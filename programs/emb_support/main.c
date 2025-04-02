/* Common main.c for the benchmarks

   Copyright (C) 2014 Embecosm Limited and University of Bristol
   Copyright (C) 2018-2019 Embecosm Limited

   Contributor: James Pallister <james.pallister@bristol.ac.uk>
   Contributor: Jeremy Bennett <jeremy.bennett@embecosm.com>

   This file is part of Embench and was formerly part of the Bristol/Embecosm
   Embedded Benchmark Suite.

   SPDX-License-Identifier: GPL-3.0-or-later */

#include "support.h"
#include "firmware.h"

#define WARMUP_HEAT 0

int __attribute__ ((used))
main (int argc __attribute__ ((unused)),
      char *argv[] __attribute__ ((unused)))
{
  int i;
  volatile int result;
  int correct;

  #ifdef ENABLE_PRINT
  print_str("Initializing Benchmark\n");
  #endif
  //initialise_board ();
  initialise_benchmark ();

  #ifdef ENABLE_PRINT
  print_str("Warming Caches\n");
  #endif
  warm_caches (WARMUP_HEAT);

  #ifdef ENABLE_PRINT
  print_str("Running Benchmark\n");
  #endif
  //start_trigger ();
  result = benchmark ();
  //stop_trigger ();

  #ifdef ENABLE_PRINT
  print_str("Finished Benchmark\n");
  #endif

  /* bmarks that use arrays will check a global array rather than int result */

  correct = verify_benchmark (result);

  #ifdef ENABLE_PRINT
  if(correct){
    print_str("PASSED\n");
    stats();
  } else {
    print_str("FAILED\n");
    stats();
  }
  #endif


  return (!correct);

}				/* main () */


/*
   Local Variables:
   mode: C
   c-file-style: "gnu"
   End:
*/
