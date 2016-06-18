from optimizeimages import pngnq, optipng

outputdir = "/home/minecraft/map"

worlds["SURVIVAL"] = "/home/minecraft/server/world"


#########
# MAPS
#########
renders["day"] = {
        "world": "SURVIVAL",
        "title": "Day Time",
        "rendermode": smooth_lighting,
        "dimension": "overworld",
        }

renders["night"] = {
        "world": "SURVIVAL",
        "title": "Night Time",
        "rendermode": smooth_night,
        "dimension": "overworld",
        }

renders["caves"] = {
        "world": "SURVIVAL",
        "title": "Caves",
        "rendermode": cave,
        "dimension": "overworld",
        }

renders["nether"] = {
        "world": "SURVIVAL",
        "title": "Nether",
        "rendermode": nether_smooth_lighting,
        "dimension": "nether",
        }

renders["end"] = {
        "world": "SURVIVAL",
        "title": "The End",
        "rendermode": smooth_lighting,
        "dimension": "end",
        }




##########
# OVERLAYS
##########

renders['biome'] = {
    'world': 'SURVIVAL',
    'rendermode': [ClearBase(), BiomeOverlay()],
    'title': "Biome Areas",
    "dimension": "overworld",
    'overlay': ['day','night','caves'],
}

renders['minerals'] = {
    'world': 'SURVIVAL',
    'rendermode': [ClearBase(), MineralOverlay()],
    'title': "Mineral Areas",
    "dimension": "overworld",
    'overlay': ['day','night','caves'],
}

renders['slime'] = {
    'world': 'SURVIVAL',
    'rendermode': [ClearBase(), SlimeOverlay()],
    'title': "Slime Areas",
    "dimension": "overworld",
    'overlay': ['day','night','caves'],
}

renders['mobs'] = {
    'world': 'SURVIVAL',
    'rendermode': [ClearBase(), SpawnOverlay()],
    'title': "Mob Density",
    "dimension": "overworld",
    'overlay': ['day','night','caves'],
}

