Made for the intent of using it on an RMM.
Working with one RMM I've noticed that the remote terminal logged in as "SYSTEM", which caused issues with Winget.
Hopefully this helps to resolve it by reinstalling it and automatically setting it up.

To use this script, open the raw file and paste this command into powershell:

irm (enter the RAW URL) | iex
