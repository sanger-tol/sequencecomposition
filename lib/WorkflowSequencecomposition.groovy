//
// This file holds several functions specific to the workflow/sequencecomposition.nf in the sanger-tol/sequencecomposition pipeline
//

import nextflow.Nextflow

class WorkflowSequencecomposition {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {

        // Check input has been provided
        if (params.input) {
            def f = new File(params.input);
            if (!f.exists()) {
                Nextflow.error "'${params.input}' doesn't exist"
            }
        } else {
            if (!params.fasta) {
                Nextflow.error "Either --input or --fasta must be provided"
            }
        }
        if (!params.outdir) {
            log.error "--outdir is mandatory"
            System.exit(1)
        }
    }

}
