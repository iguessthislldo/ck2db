/*
 * Monitor Crusadar Kings 2 game and copy autosaves to a destination directory.
 */
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <errno.h>
#include <sys/inotify.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>

#define Event struct inotify_event
#define event_buffer_size 4096
#define copy_buffer_size 1024
#define path_size 256
#define SIGINT_RETURN 130
#define debug false

const char * saves_relpath =
    "/.paradoxinteractive/Crusader Kings II/save games";
char saves_path[path_size]; // = $HOME + saves_relpath
const char * autosave_filename = "autosave.ck2";
char autosave_path[path_size]; // = saves_path + "/" + autosave_filename
const char * dest_dir_path; // = argv[1]
char dest_file_path[path_size]; // = dest_dir_path + "/" + dest_filename + N + ".ck2"

int in, watch;
bool sigint = false;
bool copy_in_progress = false;

void cleanup() {
    if (watch != -1) inotify_rm_watch(in, watch);
    if (in) close(in);
}

void sigint_handler(int signal) {
    if (copy_in_progress) {
        sigint = true;
        return;
    }
    fprintf(stderr, "Interrupted, exiting\n");
    cleanup();
    exit(SIGINT_RETURN);
}

bool copy_autosave() {
    // Get Date
#define date_size 11
    char init_date[date_size];
    char date[date_size];
    FILE * f = fopen(autosave_path, "r");
    if (!f) {
        fprintf(stderr, "Could not open %s to read date\n", autosave_path);
        return true;
    }
    //   Find Date
    const char * seek = "date=\"";
    bool found = false;
    int c, i = 0;
    while ((c = fgetc(f)) != EOF) {
        // If We are in the date string
        if (found) {
            if (c == '\"') { // End of date string
                init_date[i] = '\0';
                break;
            } else if (i >= date_size) { // " is not where it should be
                found = false;
                break;
            } else { // Copy date
                init_date[i++] = c;
            }
        // else If string matches seek so far
        } else if (c == seek[i]) {
            i++;
            if (seek[i] == '\0') { // If at end of seek
                i = 0;
                found = true;
            }
        } else { // else reset if it does not match seek
            i = 0;
            found = false;
        }
    }
    fclose(f);
    if (!found) {
        if (c == -1)
            fprintf(stderr, "Could get date, reached end of file\n");
        else 
            fprintf(stderr, "Could get date, reached end of date string buffer\n");
        return true;
    }
    if (debug) fprintf(stderr, "init_date: %s\n", init_date);
    // Reformat date
    int year, month, day;
    sscanf(init_date, "%d.%d.%d", &year, &month, &day);
    snprintf(date, date_size, "%.4d-%.2d-%.2d", year, month, day);
    if (debug) fprintf(stderr, "date: %s\n", date);

    // Build Destination Path
    snprintf(dest_file_path, path_size, "%s/%s.ck2", dest_dir_path, &date);

    fprintf(stderr, "copy \"%s\" to \"%s\"\n", autosave_path, dest_file_path);

    copy_in_progress = true;

    // Open Files
    int autosave_file = open(autosave_path, O_RDONLY);
    if (autosave_file == -1) {
        fprintf(stderr, "Could not open %s to copy from: %s\n",
            autosave_path, strerror(errno));
        return true;
    }
    int dest_file = open(dest_file_path, O_WRONLY | O_CREAT, 0644);
    if (dest_file == -1) {
        close(autosave_file);
        fprintf(stderr, "Could not open %s to copy to: %s\n",
            dest_file_path, strerror(errno));
        return true;
    }

    // Copy
    char copy_buffer[copy_buffer_size];
    ssize_t read_size;
    while ((
        read_size = read(autosave_file, copy_buffer, copy_buffer_size)
    ) > 0) {
        size_t offset = 0;
        while (read_size) {
            ssize_t wrote = write(dest_file, &copy_buffer[offset], read_size);
            if (wrote == -1) {
                fprintf(stderr, "Error writing to %s for copy: %s\n",
                    dest_file_path, strerror(errno));
                return true;
            }
            read_size -= wrote;
            offset += wrote;
        }
    }
    if (read_size == -1) {
        fprintf(stderr, "Error reading from %s for copy: %s\n",
            autosave_path, strerror(errno));
        return true;
    }

    // Close Files
    close(autosave_file);
    close(dest_file);
    copy_in_progress = false;
    if (sigint) {
        sigint_handler(0);
    }
    return false;
}

int main(int argc, char * argv[])
{
    in = 0;
    watch = -1;
    int status = 0;

    // Arguments
    if (argc != 2) {
        fprintf(stderr, "usage: capture_autosaves DEST\n");
        return 1;
    }
    dest_dir_path = argv[1];

    // Interrupt Handler
    signal(SIGINT, sigint_handler);

    // Build saves and autosave Paths
    snprintf(saves_path, path_size, "%s%s", getenv("HOME"), saves_relpath);
    snprintf(autosave_path, path_size, "%s/%s", saves_path, autosave_filename);

    // Create Destination Directory
    if (mkdir(dest_dir_path, 0755) == -1) {
        fprintf(stderr, "Error creating destination directory %s: %s\n",
            dest_dir_path, strerror(errno));
        return 1;
    }

    // Init inotify
    in = inotify_init();
    if (!in) {
        fprintf(stderr, "Could not initialize inotify\n");
        return 1;
    }

    fprintf(stderr,"Watching %s\n", saves_path);

    // Try to Watch The File
    char event_buffer[event_buffer_size];
    while (true) {

        // Try to Init Watch
        watch = inotify_add_watch(in, saves_path, IN_ALL_EVENTS);

        while (watch != -1) {

            // Read Events
            int read_size = read(in, event_buffer, event_buffer_size);
            if (read_size < 0) {
                fprintf(stderr, "Error Reading Events: %s\n", strerror(errno));
                status = 1;
                goto cleanup;
            }

            // Iterate Over Events
            Event * event;
            for (size_t offset = 0; offset < read_size;
                offset += sizeof(Event) + event->len
            ) {
                event = (Event*) &event_buffer[offset];
                if (event->mask & IN_CLOSE_WRITE &&
                    !strcmp(autosave_filename, event->name)) {
                    if (copy_autosave()) {
                        status = 1;
                        goto cleanup;
                    }
                }
                if (event->mask & IN_IGNORED) {
                    watch = -1;
                }
            }
        }

        if (debug) {
            fprintf(stderr, "Couldn't watch: %s\n", strerror(errno));
        }
    }

cleanup:
    cleanup();
    return status;
}
