#!/usr/bin/env php
<?php

require_once __DIR__ . "/../src/run_in_ilias.php";

run_in_ilias(function () : void {
    global $argv, $DIC;

    $cron_job_id = $argv[1];
    $value = $argv[2];

    if (method_exists($DIC, "cron")) {
        $cron_job = $DIC->cron()->repository()->getJobInstanceById($cron_job_id);

        if ($value) {
            $DIC->cron()->manager()->activateJob($cron_job, $DIC->user());
        } else {
            $DIC->cron()->manager()->deactivateJob($cron_job, $DIC->user());
        }
    } else {
        $cron_job = ilCronManager::getJobInstanceById($cron_job_id);

        if ($value) {
            ilCronManager::activateJob($cron_job);
        } else {
            ilCronManager::deactivateJob($cron_job);
        }
    }
});
