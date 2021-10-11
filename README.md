# sm-force-lock-class

## introduction

this plugin forces Sniper / Spy  intervals.

## installation


### extract zip

```
unzip -d /path/to/tf/addons/sourcemod ./sm-force-lock-slass.zip
```

### add your database.cfg

```
vim /path/to/tf/addons/sourcemod/configs/databases.cfg
	"force-class-interval"
	{
		"driver"			"sqlite"
		"host"				"localhost"
		"database"			"force-class-interval-sqlite"
	}
```

## cvars

* fci_force_interval = 15 (default 15. unit min.)
	* force interval time(min)"
* fci_debug = true | false (default false)
	* foce interval plugin debug cvar

## links

* https://withgod.hatenablog.com/entry/2021/10/12/012116
* 
