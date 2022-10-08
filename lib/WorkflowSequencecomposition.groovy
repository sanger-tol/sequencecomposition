//
// This file holds several functions specific to the workflow/sequencecomposition.nf in the sanger-tol/sequencecomposition pipeline
//

class WorkflowSequencecomposition {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {

        // Check input has been provided
        if (params.input) {
            def f = new File(params.input);
            if (!f.exists()) {
                log.error "'${params.input}' doesn't exist"
                System.exit(1)
            }
        } else {
            if (!params.fasta || !params.outdir) {
                log.error "Either --input, or --fasta and--outdir must be provided"
                System.exit(1)
            }
        }
    }

}
