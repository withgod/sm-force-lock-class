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

* fci_force_interval force interval time(min)"
* fci_debug foce interval plugin debug cvar
