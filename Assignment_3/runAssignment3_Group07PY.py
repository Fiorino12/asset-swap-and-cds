import pandas as pd
import numpy as np
import scipy as sc
import keras as k
import tensorflow as tf
import matplotlib.pyplot as plt
import statsmodels.api as sm

from FE_Library import yearfrac

# Not library given, but useful for simplified Regression model
import sklearn
import seaborn as sns
from sklearn import preprocessing, svm
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression

# Load Time Series
quotes = pd.read_csv("DatasetPythonAss3.csv")
quotes["Date"] = pd.to_datetime(quotes["Date"], format="%d/%m/%Y")
dates = quotes["Date"]
quotes = quotes.set_index("Date")
AAPL = quotes["AAPL"]
SPX = quotes["SPX"]

# Plot Time Series with respect to dates
plt.plot(AAPL)
plt.title("AAPL")
plt.show()
plt.plot(SPX)
plt.title("SPX")
plt.show()

# Compute Log_returns
AAPL_np = np.array(AAPL)
SPX_np = np.array(SPX)
#range gives back as output numbers between start and end-1
logreturn_AAPL = [np.log(AAPL_np[i]/AAPL_np[0]) for i in range(0, len(AAPL_np))]
logreturn_SPX = [np.log(SPX_np[i]/SPX_np[0]) for i in range(0, len(SPX_np))]
# plot of the logreturns
plt.plot(logreturn_AAPL)
plt.title("logreturn of AAPL")
plt.show()
plt.plot(logreturn_SPX)
plt.title("logreturn of SPX")
plt.show()

# Regressions with statsmodel
Y = logreturn_AAPL
X = logreturn_SPX
X = sm.add_constant(X)
model = sm.OLS(Y,X)
results = model.fit()
print('\033[1m' + "# LINEAR REGRESSION WITH STATSMODEL #" + '\033[1m')
print("The regression slope is: ", results.params[1])
print("The regression intercept is: ", results.params[0])

# Regressions with sklearn
print('\033[1m' + "\n# LINEAR REGRESSION WITH SKLEARN # " + '\033[1m')
X = np.array(logreturn_SPX).reshape(-1, 1)
y = np.array(logreturn_AAPL).reshape(-1, 1)
# We train our data splitting into training set and testing set
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size = 0.25)
lm = LinearRegression()
lm.fit(X_train, y_train)
# Exploring the result
y_pred = lm.predict(X_test)
plt.scatter(X_test, y_test, color = 'b')
plt.plot(X_test, y_pred, color = 'r')
plt.title("SKLEARN Linear Regression")
plt.show()
print("The regression slope is: ", lm.coef_)
print("The regression intercept is: ", lm.intercept_)
# We decided to use two algorithms for the Linear Regression in order to evaluate the accuracy of our result.
# We decided to compare with sklearn since it is one of the most used algorithm for this kind of work, and our result is
# really close to the one obtained with sklearn.

# YearFrac
print('\033[1m' + "\n# YEAR FRACTION BETWEEN THE FIRST AND LAST DATE IN ACT/365 #" + '\033[1m')
dates_vc = pd.array(dates)
AAPLfirstlastdate = yearfrac(dates_vc[0], dates_vc[len(dates_vc)-1], basis=3)
print("The year fraction between the first and last date in ACT/365 is: ", AAPLfirstlastdate)

# Interpolate
print('\033[1m' + "\n# INTERPOLATION #" + '\033[1m')
f = [1, 2, 3.5, 4, 2]
x = [0, 1, 2, 3, 4]
interp_x = 2.7
interp_f = np.interp(interp_x, x,f)
print("The interpolated value is: ", interp_f)
# We used a function from numpy in order to interpolate our needed value
# In order to do that,  we gave the value we needed to interpolate and two "reference" arrays.
# np.interp will return the value

# Simulation
print('\033[1m' + "\n# SIMULATION OF A STANDARD NORMAL VARIABLE #" + '\033[1m')
mu = 0 #mean
sigma = 1 #standard deviation
z = sc.stats.norm.rvs(loc = mu, scale = sigma, size = 10000000)
print("The mean is", np.mean(z))
print("The variance is", np.var(z))
print("The gaussian CDF evaluated in the quantile 0.9 is", np.mean(sc.stats.norm.cdf(z,0.9)))
# and we obtained values typical of a standard normal distribution.

# Minimization

# Analytical
# we want to minimize f(x,y) = (x-3)^2 + (y-7) ^ 2
#
# First we need to impose that the gradient is null i.e.
# df/dx = 2(x-3)
# df/dy = 2(y-7)
# Let gradient = (df/dx; df/dy), then it is null if and only if df/dx = 0 and df/dy = 0
# i.e. for x = 3, y = 7. So our candidate minimum point would be (3, 7)
#
# Now we need to compute the hessian and see if it is positive definite.
# d2f/dx2 = 2
# d2f/dy2 = 2
# d2f/dxdy = 0
# Let hessian = (d2f/dx2 d2f/dxdy; d2f/dxdy d2f/dy2), then we obtain
# hessian = [2 0; 0 2], and it is a positive definite matrix
#
# So (3,7) is a minimum point and f((3,7)) = 0

#Numerical
print('\033[1m' + "\n# COMPUTING OF THE MINIMUM OF A FUNCTION WITH A NUMERICAL APPROACH #" + '\033[1m')
# we define a function to be used in .optimize.fmin
def f(x):
    exp = (x[0]-3)**2 + (x[1]-7)**2
    return exp
minimum = sc.optimize.fmin(f, np.array([0,0]))
print("The minimum is in \n x= ", minimum[0], "\n y= ", minimum[1])
#We notice really close results between Analytical and Numerical approach: the error is given by the approximation made by numerical approach.
