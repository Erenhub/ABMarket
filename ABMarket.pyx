"""
A simple agent-based model of a financial market.

(c) 2012 Jack Peterson (jack@tinybike.net)
"""

from __future__ import division
from random import random, shuffle
import pylab as p
from collections import Counter
from math import *
from time import *

class Trader:
	def __init__(self, double buy, double sell):
		cdef:
			double b
			double s
			int bCount
			int sCount
		self.b = buy
		self.s = sell
		self.bCount = 0
		self.sCount = 0
		self.actionList = []	# buy = 1, sell = -1
	def showProb(self):
		print str(self.b) + " " + str(self.s)
	def updateProb(self):
		# Buy/sell probs proportional to "winning streak"
		cdef int streak
		streak = 1
		while streak < len(self.actionList) and self.actionList[-streak] == self.actionList[-(streak + 1)]:
			streak += 1
		if self.actionList[-1] == 1:
			self.b = streak
			self.s = 1
		else:
			self.b = 1
			self.s = streak
	def calcProb(self):
		self.total = self.b + self.s
		self.bPr = self.b / self.total
	def buyAction(self):
		self.bCount += 1
		self.actionList.append(1)
	def sellAction(self):
		self.sCount += 1
		self.actionList.append(-1)
	def finalPosition(self):
		return self.bCount - self.sCount

def timeStep(T, timestep):
	# Buy or sell?
	# Comment out the next 2 lines for constant buy/sell probs:
	if timestep > 0:
		T.updateProb()
	T.calcProb()
	action = random()
	if action < T.bPr:
		T.buyAction()
	else:
		T.sellAction()
		
def marketSim(int N, int tMax, double initBuy, double initSell):
	# Create N traders
	traderList = []
	for traders in xrange(N):
		traderList.append(Trader(initBuy, initSell))
	
	# Run simulation for tMax time steps
	for timestep in xrange(tMax):
		# Randomly re-order the traders' order-of-actions at each time step
		shuffled = range(N)
		shuffle(shuffled)
		for traders in shuffled:
			timeStep(traderList[traders], timestep)
			
	# Return final positions
	positions = [traderList[i].finalPosition() for i in xrange(N)]
	return positions

def calcStats(positionsList, numSims):
	# Counts and list of unique x-values across all simulations
	counts = [Counter(i) for i in positionsList]
	keys = [i.keys() for i in counts]
	uniqueKeys = list(set(sum(keys, [])))
	
	# Calculate mean and variance of counts across histograms
	meanCounts = {}
	varCounts = {}
	for j in uniqueKeys:
		meanCounts[j] = 0
		for i in xrange(numSims):
			meanCounts[j] += counts[i][j]
		meanCounts[j] /= numSims
		varCounts[j] = 0
		for i in xrange(numSims):
			varCounts[j] += (counts[i][j] - meanCounts[j]) ** 2
		varCounts[j] /= numSims - 1
	return meanCounts, varCounts
	
def showPlot(x, y):
	p.figure()
	p.semilogy(x, y, '.')
	p.xlabel('position')
	p.ylabel('mean count')
	p.show()
	
def writeCSV(x, y):
	with open('ABMarket.csv', 'w') as f:
		for i in xrange(len(x)):
			f.write(str(x[i]) + ',' + str(y[i]) + '\n')			

def main():
	# Parameters
	cdef:
		int numSims
		int numTraders
		int tMax
		double initBuy
		double initSell
	numSims = 1000		# Number of simulations
	numTraders = 100	# Number of traders
	tMax = 1000			# Length of simulation
	initBuy = 1.0		# Initial buy rate
	initSell = 1.0		# Initial sell rate
	
	# Run simulations
	positionsList = [marketSim(numTraders, tMax, initBuy, initSell) for i in xrange(numSims)]
	
	# Process positions list and calculate statistics
	meanCounts, varCounts = calcStats(positionsList, numSims)
	
	# Plot results
	showPlot(meanCounts.keys(), meanCounts.values())
	
	# Write to file
	writeCSV(meanCounts.keys(), meanCounts.values())

if __name__ == "__main__":
	main()