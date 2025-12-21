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
    "ffprobe"     => "/usr/bin/ffprobe",
    "mediainfo"   => "/usr/bin/mediainfo",
    "sox"         => "/usr/bin/sox",
    "dumptorrent" => "/usr/bin/dumptorrent",
);


$localhosts = array("127.0.0.1", "localhost");
$profilePath = "../share";
$profileMask = 0777;
$tempDirectory = null;
$canUseXSendFile = false;
$locale = "en";

$topDirectory = "/downloads"; 
$profilePath = "/config/rutorrent/share";
$profileMask = 0777;

$do_diagnostic = true;
$saveUploadedTorrents = true;
$throttleMaxSpeed = 327625 * 1024;