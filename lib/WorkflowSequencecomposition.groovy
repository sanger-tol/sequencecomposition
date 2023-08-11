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
            if (!params.fasta || !params.outdir) {
                Nextflow.error "Either --input, or --fasta and--outdir must be provided"
            }
        }
    }

}
