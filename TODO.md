TODO:
====

* Ping the API and reconnect if necessary
* Extract db and API credentials to ENV vars (.env)
* Cleanup requires
* Setup trap_signals properly (probably TERM, QUIT and INT. I don't think we can handle KILL)
* Add unit test
* Setup Capistrano to:
	* Check if Redis is running (if not, start it)
	* Restart the app daemons (kill and start)
	* Leave log and tmp folders as shared so we don't lose them on deploys
