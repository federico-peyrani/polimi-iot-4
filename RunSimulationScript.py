import sys

from TOSSIM import *

print "********************************************"
print "*                                          *"
print "*             TOSSIM Script                *"
print "*                                          *"
print "********************************************"

# Config
topo_file = "topology.txt"
model_file = "meyer-heavy.txt"

mote_1_start = 0
mote_2_start = 5
simulation_outfile = "output/simulation.txt"

debug_channels = ["boot", "radio", "req", "resp"]

# Initialization
t = Tossim([])

print "Initializing mac...."
mac = t.mac()
print "Initializing radio channels...."
radio = t.radio()
print "    using topology file:", topo_file
print "    using noise file:", model_file
print "Initializing simulator...."
t.init()

print "Saving sensors simulation output to:", simulation_outfile
simulation_out = open(simulation_outfile, "w")

out = open(simulation_outfile, "w")

# Add debug channel
for debug_channel in debug_channels:
    t.addChannel(debug_channel, out)

print "Creating node 1..."
node1 = t.getNode(1)
time1 = mote_1_start * t.ticksPerSecond()
node1.bootAtTime(time1)
print ">>> Will boot at time", mote_1_start, "[sec]"

print "Creating node 2..."
node2 = t.getNode(2)
time2 = mote_2_start * t.ticksPerSecond()
node2.bootAtTime(time2)
print ">>> Will boot at time", mote_2_start, "[sec]"

print "Creating radio channels..."
f = open(topo_file, "r")
lines = f.readlines()
for line in lines:
    s = line.split()
    if len(s) > 0:
        print ">>> Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
        radio.add(int(s[0]), int(s[1]), float(s[2]))

# creation of channel model
print "Initializing Closest Pattern Matching (CPM)..."
noise = open(model_file, "r")
lines = noise.readlines()
compl = 0
mid_compl = 0

print "Reading noise model data file:", model_file
print "Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and (compl < 10000):
        val = int(str)
        mid_compl = mid_compl + 1
        if mid_compl > 5000:
            compl = compl + mid_compl
            mid_compl = 0
            sys.stdout.write("#")
            sys.stdout.flush()
        for i in range(1, 3):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!"

for i in range(1, 3):
    print ">>>Creating noise model for node:", i
    t.getNode(i).createNoiseModel()

print "Start simulation with TOSSIM!\n\n"

for i in range(0, 1400):
    t.runNextEvent()

print "\n\nSimulation finished!"
