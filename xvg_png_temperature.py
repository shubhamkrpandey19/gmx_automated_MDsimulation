import numpy as np
import matplotlib.pyplot as plt

# Read the XVG file
data = np.loadtxt('temperature.xvg', comments=('#', '@'),skiprows=1)

# Extract the x and y data
x = data[:, 0]
y = data[:, 1]
avg_y = np.mean(y)

# Create the plot
plt.plot(x, y)
plt.axhline(y=avg_y, color= 'red') 
# Add a title and labels
plt.title('Temperature')
plt.xlabel('Time (ps)')
plt.ylabel('Temperature (K)')

# Show the plot
plt.show()