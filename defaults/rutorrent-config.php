<?php
// Connection to rTorrent
$scgi_port = 0;
$scgi_host = "unix:///run/ops/rtorrent.sock";
$XMLRPCMountPoint = "/RPC2";

// External binary paths
$pathToExternals = array(
    "php"         => "/usr/bin/php",
    "curl"        => "/usr/bin/curl",
    "gzip"        => "/usr/bin/gzip",
    "id"          => "/usr/bin/id",
    "stat"        => "/usr/bin/stat",
    "unrar"       => "/usr/bin/unrar",
    "dumptorrent" => "/usr/bin/dumptorrent",
);

$localhosts = array("127.0.0.1", "localhost");
$topDirectory = "/downloads";
$profilePath = "/config/rutorrent/share";
$profileMask = 0770;
$tempDirectory = null;
$canUseXSendFile = false;
$locale = "en";

$do_diagnostic = true;
$saveUploadedTorrents = true;
$throttleMaxSpeed = 327625 * 1024;
