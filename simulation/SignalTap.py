import numpy as np
import matplotlib.pyplot as plt

data_binary = np.loadtxt('data_packet.csv', delimiter=',', dtype=bool, skiprows=0, usecols=(0,1,2,3,4,5,6,7,8,9,10,11,12,13))

vref = 1.8 #Volt
data_decimal = data_binary[:,13]*2**13 + data_binary[:,12]*2**12 + data_binary[:,11]*2**11 + data_binary[:,10]*2**10 + data_binary[:,9]*2**9 + \
				data_binary[:,8]*2**8 + data_binary[:,7]*2**7 + data_binary[:,6]*2**6 + data_binary[:,5]*2**5 + data_binary[:,4]*2**4 + \
				data_binary[:,3]*2**3 + data_binary[:,2]*2**2 + data_binary[:,1]*2**1 + data_binary[:,0]*2**0

# b = data_decimal[1:]
# a = data_decimal[:-1]
# slope = b - a +8500
# slope = slope[3500:6000]
# data_decimal = data_decimal[3500:6000]

# bits_receive = np.loadtxt('dataout_modelsim.txt', dtype=bool, skiprows=24)*1000+8500

# plt.figure(dpi=200, figsize=(16,9))	
plt.plot(np.arange(np.size(data_decimal))/20000.,data_decimal)
# plt.plot(np.arange(np.size(bits_receive))/20000., bits_receive)
plt.xlabel('Time (ms)', fontsize=16)
plt.ylabel('ADC Counts', fontsize=16)
plt.show()
# plt.savefig('counts.png')

# first=3809 - 30
# delta=4300
# for i in range(14):
	# waveform = data_decimal[first+i*delta:first+i*delta+200]
	# plt.plot(range(np.size(waveform)), waveform, linestyle=':', marker= '.')
# plt.show()