<?php
// Connection to rTorrent
$scgi_port = 0;
$scgi_host = "unix:///run/ops/rtorrent.sock";

// NEW: Silence PHP 8.3 warnings by defining these defaults
$XMLRPCMountPoint = "/RPC2";
$do_diagnostic = true;
$log_file = "/run/ops/rutorrent.log";

// External binary paths
$pathToExternals = array(
    "php"         => "/usr/bin/php",
    "curl"        => "/usr/bin/curl",
    "gzip"        => "/usr/bin/gzip",
    "id"          => "/usr/bin/id",
    "stat"        => "/usr/bin/stat",
    "unrar"       => "/usr/bin/unrar",
    "ffprobe"     => "/usr/bin/ffprobe",
    "mediainfo"   => "/usr/bin/mediainfo",
    "sox"         => "/usr/bin/sox",
    "dumptorrent" => "/usr/bin/dumptorrent",
);

// Other required defaults
$localhosts = array("127.0.0.1", "localhost");
$profilePath = "../share";
$profileMask = 0777;
$tempDirectory = null;
$canUseXSendFile = false;
$locale = "en";

// FIX: Absolute paths to stop the "torrents directory" error
$topDirectory = '/'; 
$profilePath = '/var/www/rutorrent/share';
$profileMask = 0777;

// FIX: Silence PHP 8.3 warnings and fix diagnostic checks
$do_diagnostic = true;
$log_file = '/run/ops/rutorrent.log';
$saveUploadedTorrents = true;
$throttleMaxSpeed = 327625 * 1024; // Fixes throttle plugin failure