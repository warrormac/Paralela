#include <mpi.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <sys/time.h>
#include <pthread.h>


int thread_count;
int barrier_thread_count = 0;
pthread_mutex_t barrier_mutex;
pthread_cond_t ok_to_proceed;


void* Thread_work(void* rank);

/*--------------------------------------------------------------------*/
int main(int argc, char* argv[]) {
        long thread;
        pthread_t* thread_handles;
        double start, finish;
        thread_count = strtol(argv[1], NULL, 10);
        thread_handles = malloc(thread_count * sizeof(pthread_t));
        pthread_mutex_init(&barrier_mutex, NULL);
        pthread_cond_init(&ok_to_proceed, NULL);

        for (thread = 0; thread < thread_count; thread++)
                pthread_create(&thread_handles[thread], NULL,
                        Thread_work, (void*)thread);
        for (thread = 0; thread < thread_count; thread++) {
                pthread_join(thread_handles[thread], NULL);
        }

        printf("Elapsed time = %e seconds\n", finish - start);
        pthread_mutex_destroy(&barrier_mutex);
        pthread_cond_destroy(&ok_to_proceed);
        free(thread_handles);
        return 0;
} /* main */


void* Thread_work(void* rank) {
# ifdef DEBUG
        long my_rank = (long)rank;
# endif
        int i;
        for (i = 0; i <10; i++) {
                pthread_mutex_lock(&barrier_mutex);
                barrier_thread_count++;
                if (barrier_thread_count == thread_count) {
                        barrier_thread_count = 0;
# ifdef DEBUG
                        printf("Thread %ld > Signalling other threads in barrier %d\n",
                                my_rank, i);
                        fflush(stdout);
# endif
                        pthread_cond_broadcast(&ok_to_proceed);
                }
                else {
                        // Wait unlocks mutex and puts thread to sleep.
                        // Put wait in while loop in case some other
                        // event awakens thread.
                        while (pthread_cond_wait(&ok_to_proceed,
                                &barrier_mutex) != 0);
                        // Mutex is relocked at this point.
# ifdef DEBUG
                        printf("Thread %ld > Awakened in barrier %d\n", my_rank, i);
                        fflush(stdout);
# endif
                }
                pthread_mutex_unlock(&barrier_mutex);
# ifdef DEBUG
                if (my_rank == 0) {
                        printf("All threads completed barrier %d\n", i);
                        fflush(stdout);
                }
# endif
        }
}

