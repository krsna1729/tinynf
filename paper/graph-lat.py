#!/usr/bin/python3

import matplotlib as mpl
import common
import pathlib
import sys

if len(sys.argv) < 3:
  print('[ERROR] Args: <name> <file>*')
  sys.exit(1)

name = sys.argv[1]
files = sys.argv[2:]

values = {}
lat_min = 10000000
lat_9999th = 0
for file in files:
  path = pathlib.Path(file)
  lats = [float(l) / 1000.0 for l in path.read_text().splitlines()]
  lats = sorted(lats, reverse=True)
  lat_min = min(lat_min, lats[-1])
  lat_9999th = max(lat_9999th, lats[int(0.0001*len(lats))])
  values[file] = lats

plt, ax, fig = common.get_pyplot_ax_fig(figsize=[6.2, 2.4]) # half usual height
ax.grid(True, color='xkcd:light grey')
ax.set_axisbelow(True) # ensure grid is below data

lines = []
for (folder, lats) in values.items():
  (color, label, marker) = common.get_color_label_marker(folder) # this works with folder names due to how we determine this info...
  x = lats
  y = [(float(n+1)/(len(lats)+1)) for n in range(len(lats))]
  ax.plot(x, y, color=color, label=label)

plt.legend(loc='upper right', handletextpad=0.3, borderaxespad=0, facecolor='white', framealpha=1, edgecolor='white')
plt.yscale('log', basey=10, nonposy='mask')
# Primorac et al. 2017, beyond 99.99th percentile NIC timestamp accuracy is not reliable
ax.set_ylim(bottom=0.0001, top=1.03) # 1.03 so the top line doesn't get cut off
ax.set_xlim(lat_min, lat_9999th)

# Custom ax labels
fig.text(0.5, -0.04, 'Latency (\u03BCs)', ha='center')
fig.text(0.02, 0.5, 'CCDF', va='center', rotation='vertical')
common.save_plot(plt, 'Latencies ' + name)
