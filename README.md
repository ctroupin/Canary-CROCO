# Canary - CROCO

Implementation of the [CROCO](https://www.croco-ocean.org/) numerical model around the Canary Islands.


https://github.com/user-attachments/assets/36518d5f-7ee1-41b5-93d8-0112c2ded293


## Project structure

```bash
├── bib 	# .bib file storing useful references
|
├── doc 	# documentation and presentations
|
├── figures	# plots and maps
│   
├── input	# input files to be used with CROCO (`.ini` files)
│   
└── src		# code for the plotting of results
```

```geojson
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": 1,
      "properties": {
        "ID": 0
      },
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
             [
              -19.49170859801714,
              30.842575145933793
            ],
            [
              -19.49170859801714,
              26.17776606462762
            ],
            [
              -9.559587972756844,
              26.17776606462762
            ],
            [
              -9.559587972756844,
              30.842575145933793
            ],
            [
              -19.49170859801714,
              30.842575145933793
            ]
          ]
        ]
      }
    }
  ]
}
```


