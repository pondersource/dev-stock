/**********************************************
 * Improved Test Workflow Orchestration Script
 *
 * This script triggers multiple GitHub Actions
 * workflows in batched parallel mode, waits
 * for each to complete, and moves on to the
 * next batch until all workflows finish.
 **********************************************/


const WORKFLOWS = [
  'login-nc-v27.yml',
  'login-nc-v28.yml',
  'login-oc-v10.yml',
  'login-ocis-v5.yml',
  'login-os-v1.yml',
  'login-sf-v11.yml',
  'share-link-nc-v27-nc-v27.yml',
  'share-link-nc-v27-nc-v28.yml',
  'share-link-nc-v27-oc-v10.yml',
  'share-link-nc-v27-os-v1.yml',
  'share-link-nc-v28-nc-v27.yml',
  'share-link-nc-v28-nc-v28.yml',
  'share-link-nc-v28-oc-v10.yml',
  'share-link-oc-v10-nc-v27.yml',
  'share-link-oc-v10-nc-v28.yml',
  'share-link-oc-v10-oc-v10.yml',
  'share-with-nc-v27-nc-v27.yml',
  'share-with-nc-v27-nc-v28.yml',
  'share-with-nc-v27-oc-v10.yml',
  'share-with-nc-v27-os-v1.yml',
  'share-with-nc-v28-nc-v27.yml',
  'share-with-nc-v28-nc-v28.yml',
  'share-with-nc-v28-oc-v10.yml',
  'share-with-nc-v28-os-v1.yml',
  'share-with-oc-v10-nc-v27.yml',
  'share-with-oc-v10-nc-v28.yml',
  'share-with-oc-v10-oc-v10.yml',
  'share-with-oc-v10-os-v1.yml',
  'share-with-os-v1-nc-v27.yml',
  'share-with-os-v1-nc-v28.yml',
  'share-with-os-v1-oc-v10.yml',
  'share-with-os-v1-os-v1.yml',
  'share-with-sf-v11-sf-v11.yml',
  'invite-link-nc-sm-v27-nc-sm-v27.yml',
  'invite-link-nc-sm-v27-oc-sm-v10.yml',
  'invite-link-nc-sm-v27-ocis-v5.yml',
  'invite-link-oc-sm-v10-nc-sm-v27.yml',
  'invite-link-oc-sm-v10-oc-sm-v10.yml',
  'invite-link-oc-sm-v10-ocis-v5.yml',
  'invite-link-ocis-v5-nc-sm-v27.yml',
  'invite-link-ocis-v5-oc-sm-v10.yml',
  'invite-link-ocis-v5-ocis-v5.yml'
];

// Constants controlling polling / batching behavior
const POLL_INTERVAL_STATUS = 30000; // ms between each run status check
const POLL_INTERVAL_RUN_ID = 5000;  // ms between each new run ID check
const RUN_ID_TIMEOUT = 60000;       // ms to wait for a new run to appear
const INITIAL_RUN_ID_DELAY = 5000;  // ms initial wait before checking for run ID
const DEFAULT_BATCH_SIZE = 5;       // Workflows to run concurrently per batch

/**
 * Pause execution for the given number of milliseconds.
 * @param {number} ms - Milliseconds to sleep.
 * @returns {Promise<void>}
 */
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Wait until a given workflow run completes by polling its status.
 * @param {Object} github - GitHub API client.
 * @param {string} owner - Repository owner.
 * @param {string} repo - Repository name.
 * @param {number} runId - Workflow run ID.
 * @returns {Promise<string>} Conclusion of the workflow (e.g. 'success' or 'failure').
 */
async function waitForWorkflowCompletion(github, owner, repo, runId) {
  while (true) {
    try {
      const { data: run } = await github.rest.actions.getWorkflowRun({
        owner,
        repo,
        run_id: runId
      });

      if (run.status === 'completed') {
        return run.conclusion;
      }
    } catch (error) {
      console.error(`Error fetching run ${runId}: ${error.message}`);
    }

    await sleep(POLL_INTERVAL_STATUS);
  }
}

/**
 * Find the run ID of a newly triggered workflow by polling for an 'in_progress' run.
 * @param {Object} github - GitHub API client.
 * @param {Object} params - { owner, repo, workflow_id, branch } for the GitHub API.
 * @returns {Promise<number>} The detected run ID of the new workflow.
 * @throws If no new run is found within the timeout.
 */
async function findNewRunId(github, params) {
  await sleep(INITIAL_RUN_ID_DELAY);
  const startTime = Date.now();

  while (Date.now() - startTime < RUN_ID_TIMEOUT) {
    try {
      const { data: runs } = await github.rest.actions.listWorkflowRuns({
        ...params,
        status: 'in_progress',
        per_page: 1
      });

      if (runs.total_count > 0 && runs.workflow_runs.length > 0) {
        return runs.workflow_runs[0].id;
      }
    } catch (error) {
      console.error(`Error listing runs for workflow ${params.workflow_id}: ${error.message}`);
    }

    await sleep(POLL_INTERVAL_RUN_ID);
  }

  throw new Error(
    `Timeout: No in-progress run found for workflow ${params.workflow_id} within ${RUN_ID_TIMEOUT}ms`
  );
}

/**
 * Dispatch a workflow and retrieve the run ID once it's in progress.
 * @param {Object} github - GitHub API client.
 * @param {Object} context - GitHub Actions context (includes repo/owner/ref).
 * @param {string} workflow - Workflow file name to trigger.
 * @returns {Promise<{ name: string, runId: number }>} Name and runId of triggered workflow.
 */
async function triggerWorkflow(github, context, workflow) {
  console.log(`Triggering workflow: ${workflow}`);
  const { owner, repo } = context.repo;

  // Dispatch the workflow
  await github.rest.actions.createWorkflowDispatch({
    owner,
    repo,
    workflow_id: workflow,
    ref: context.ref
  });

  // Infer branch name from ref (e.g. 'refs/heads/main' -> 'main')
  const branch = context.ref.replace(/^refs\/heads\//, '');
  const runId = await findNewRunId(github, {
    owner,
    repo,
    workflow_id: workflow,
    branch
  });

  return { name: workflow, runId };
}

/**
 * Main orchestration entry point. 
 * Batches workflows, triggers them in parallel, then waits for completion.
 * Moves on to the next batch until all workflows finish.
 *
 * @param {Object} github - GitHub API client.
 * @param {Object} context - GitHub Actions context.
 */
module.exports = async function orchestrateTests(github, context) {
  // Optionally, this could come from inputs or environment
  const batchSize = DEFAULT_BATCH_SIZE;
  const totalWorkflows = WORKFLOWS.length;
  const totalBatches = Math.ceil(totalWorkflows / batchSize);
  let allSucceeded = true;

  console.log(`Starting orchestration of ${totalWorkflows} workflows in ${totalBatches} batches...`);

  for (let i = 0; i < totalWorkflows; i += batchSize) {
    const currentBatch = WORKFLOWS.slice(i, i + batchSize);
    const batchNumber = Math.floor(i / batchSize) + 1;

    console.log(`\nProcessing batch ${batchNumber} of ${totalBatches}...`);
    const triggeredWorkflows = [];

    // Trigger workflows in the current batch
    for (const workflow of currentBatch) {
      try {
        const wf = await triggerWorkflow(github, context, workflow);
        triggeredWorkflows.push(wf);
      } catch (error) {
        console.error(`Error triggering workflow ${workflow}: ${error.message}`);
        allSucceeded = false;
      }
    }

    // Wait for all triggered workflows in the batch to complete
    await Promise.all(
      triggeredWorkflows.map(async (wf) => {
        console.log(`Waiting for workflow: ${wf.name} (Run ID: ${wf.runId}) to complete...`);
        const conclusion = await waitForWorkflowCompletion(
          github,
          context.repo.owner,
          context.repo.repo,
          wf.runId
        );
        console.log(`Workflow ${wf.name} completed with conclusion: ${conclusion}`);
        if (conclusion !== 'success') {
          allSucceeded = false;
        }
      })
    );
  }

  console.log('\nAll test workflows have completed.');
  return allSucceeded;
};
