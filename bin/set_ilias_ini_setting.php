#!/usr/bin/env php
<?php

require_once __DIR__ . "/../src/run_in_ilias.php";

run_in_ilias(function () : void {
    global $argv, $DIC;

    $module = $argv[1];
    $key = $argv[2];
    $value = $argv[3];

    $DIC->iliasIni()->setVariable($module, $key, $value);
    $DIC->iliasIni()->write();
});
