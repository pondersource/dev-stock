/**
 * Orchestrates test workflow execution in batches.
 * Triggers workflows and waits for their completion before moving to the next batch.
 */

const workflows = [
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

/**
 * Waits for a workflow run to complete
 * @param {Object} github - GitHub API client
 * @param {string} owner - Repository owner
 * @param {string} repo - Repository name
 * @param {number} runId - Workflow run ID
 * @returns {Promise<string>} Workflow conclusion
 */
async function waitForWorkflow(github, owner, repo, runId) {
  while (true) {
    const { data: run } = await github.rest.actions.getWorkflowRun({
      owner,
      repo,
      run_id: runId
    });

    if (run.status === 'completed') {
      return run.conclusion;
    }

    // Wait 30 seconds before checking again
    await new Promise(resolve => setTimeout(resolve, 30000));
  }
}

/**
 * Main orchestration function
 * @param {Object} github - GitHub API client
 * @param {Object} context - GitHub Actions context
 */
module.exports = async function orchestrateTests(github, context) {
  // Process workflows in batches of 5 to avoid overloading
  const batchSize = 5;
  for (let i = 0; i < workflows.length; i += batchSize) {
    const batch = workflows.slice(i, i + batchSize);
    console.log(`Processing batch ${i / batchSize + 1}/${Math.ceil(workflows.length / batchSize)}`);

    const runningWorkflows = [];

    // Trigger workflows in this batch
    for (const workflow of batch) {
      console.log(`Triggering workflow: ${workflow}`);
      try {
        await github.rest.actions.createWorkflowDispatch({
          owner: context.repo.owner,
          repo: context.repo.repo,
          workflow_id: workflow,
          ref: context.ref,
        });

        // Get the run ID for the workflow we just triggered
        const { data: runs } = await github.rest.actions.listWorkflowRuns({
          owner: context.repo.owner,
          repo: context.repo.repo,
          workflow_id: workflow,
          branch: context.ref.replace('refs/heads/', ''),
          per_page: 1
        });

        if (runs.total_count > 0) {
          runningWorkflows.push({
            name: workflow,
            runId: runs.workflow_runs[0].id
          });
        }
      } catch (error) {
        console.log(`Error triggering workflow ${workflow}: ${error.message}`);
      }
    }

    // Wait for all workflows in this batch to complete
    for (const wf of runningWorkflows) {
      console.log(`Waiting for workflow: ${wf.name}`);
      const conclusion = await waitForWorkflow(
        github,
        context.repo.owner,
        context.repo.repo,
        wf.runId
      );
      console.log(`Workflow ${wf.name} completed with conclusion: ${conclusion}`);
    }
  }

  console.log('All test workflows have completed');
};
