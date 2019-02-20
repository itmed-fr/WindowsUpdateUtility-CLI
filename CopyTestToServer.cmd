@ECHO OFF

REM Copy Test locally to Test on the Server
robocopy c:\test\wuu2 \\VRCWU001.vdlgroep.local\c$\Users\Public\Desktop\WUU2\ /MIR /R:1 /W:1 /Z /MON:1 /XF .git* /XD .git*

REM Copy Test from Server to Production on the OtherServer
REM RoboCopy \\VRCWU001.vdlgroep.local\c$\Users\Public\Desktop\WUU2\ \\ETGEWU001.vdlgroep.local\c$\Users\Public\Desktop\WUU2\ /MIR /R:1 /W:1 /Z /XF .git* /XD .git*

pause