<?php
// functions.php

function secure () {
  if (!($_SESSION['studentnummer']) || ($_SESSION['studentnummer'] == "")) {
    Header("Location: ./login.php");
    exit();
  }
}
function login_check ($forms) {
  $error = "";
  $studentnummer = $forms["student"];
  if (trim($studentnummer) == "") $error .= "<li>Het studentnummer is niet ingevuld</li>";
  if (trim($error)!="") return $error;
}

function login ($forms) {
  $studentnummer = $forms["student"];
  return $studentnummer;
}
?>