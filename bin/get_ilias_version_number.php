#!/usr/bin/env php
<?php

$web_dir = filter_input(INPUT_ENV, "ILIAS_WEB_DIR");

require_once $web_dir . "/include/inc.ilias_version.php";

echo ILIAS_VERSION_NUMERIC;
