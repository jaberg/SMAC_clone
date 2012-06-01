/*
 * MATLAB Compiler: 4.13 (R2010a)
 * Date: Mon Jul 18 16:18:35 2011
 * Arguments: "-B" "macro_default" "-W" "java:Weibull,WeibullDist" "-T" "link:lib" "-d" 
 * "/ubc/cs/project/arrow/hutter/altuning/matlab/AClion_for_Jon/regression/javaregtrees/Weibull/src" 
 * "-w" "enable:specified_file_mismatch" "-w" "enable:repeated_file" "-w" 
 * "enable:switch_ignored" "-w" "enable:missing_lib_sentinel" "-w" "enable:demo_license" 
 * "-v" 
 * "class{WeibullDist:/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblcdf.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblfit.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblinv.m,/cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblrnd.m}" 
 */

package Weibull;

import com.mathworks.toolbox.javabuilder.*;
import com.mathworks.toolbox.javabuilder.internal.*;
import java.util.*;

/**
 * The <code>WeibullDist</code> class provides a Java interface to the M-functions
 * from the files:
 * <pre>
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblcdf.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblfit.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblinv.m
 *  /cs/local/generic/lib/pkg/matlab-7.10/toolbox/stats/wblrnd.m
 * </pre>
 * The {@link #dispose} method <b>must</b> be called on a <code>WeibullDist</code> 
 * instance when it is no longer needed to ensure that native resources allocated by this 
 * class are properly freed.
 * @version 0.0
 */
public class WeibullDist extends MWComponentInstance<WeibullDist>
{
    /**
     * Tracks all instances of this class to ensure their dispose method is
     * called on shutdown.
     */
    private static final Set<Disposable> sInstances = new HashSet<Disposable>();

    /**
     * Maintains information used in calling the <code>wblcdf</code> M-function.
     */
    private static final MWFunctionSignature sWblcdfSignature =
        new MWFunctionSignature(/* max outputs = */ 3,
                                /* has varargout = */ false,
                                /* function name = */ "wblcdf",
                                /* max inputs = */ 5,
                                /* has varargin = */ false);
    /**
     * Maintains information used in calling the <code>wblfit</code> M-function.
     */
    private static final MWFunctionSignature sWblfitSignature =
        new MWFunctionSignature(/* max outputs = */ 2,
                                /* has varargout = */ false,
                                /* function name = */ "wblfit",
                                /* max inputs = */ 5,
                                /* has varargin = */ false);
    /**
     * Maintains information used in calling the <code>wblinv</code> M-function.
     */
    private static final MWFunctionSignature sWblinvSignature =
        new MWFunctionSignature(/* max outputs = */ 3,
                                /* has varargout = */ false,
                                /* function name = */ "wblinv",
                                /* max inputs = */ 5,
                                /* has varargin = */ false);
    /**
     * Maintains information used in calling the <code>wblrnd</code> M-function.
     */
    private static final MWFunctionSignature sWblrndSignature =
        new MWFunctionSignature(/* max outputs = */ 1,
                                /* has varargout = */ false,
                                /* function name = */ "wblrnd",
                                /* max inputs = */ 3,
                                /* has varargin = */ true);

    /**
     * Shared initialization implementation - private
     */
    private WeibullDist (final MWMCR mcr) throws MWException
    {
        super(mcr);
        // add this to sInstances
        synchronized(WeibullDist.class) {
            sInstances.add(this);
        }
    }

    /**
     * Constructs a new instance of the <code>WeibullDist</code> class.
     */
    public WeibullDist() throws MWException
    {
        this(WeibullMCRFactory.newInstance());
    }
    
    private static MWComponentOptions getPathToComponentOptions(String path)
    {
        MWComponentOptions options = new MWComponentOptions(new MWCtfExtractLocation(path),
                                                            new MWCtfDirectorySource(path));
        return options;
    }
    
    /**
     * @deprecated Please use the constructor {@link #WeibullDist(MWComponentOptions componentOptions)}.
     * The <code>com.mathworks.toolbox.javabuilder.MWComponentOptions</code> class provides API to set the
     * path to the component.
     * @param pathToComponent Path to component directory.
     */
    public WeibullDist(String pathToComponent) throws MWException
    {
        this(WeibullMCRFactory.newInstance(getPathToComponentOptions(pathToComponent)));
    }
    
    /**
     * Constructs a new instance of the <code>WeibullDist</code> class. Use this 
     * constructor to specify the options required to instantiate this component.  The 
     * options will be specific to the instance of this component being created.
     * @param componentOptions Options specific to the component.
     */
    public WeibullDist(MWComponentOptions componentOptions) throws MWException
    {
        this(WeibullMCRFactory.newInstance(componentOptions));
    }
    
    /** Frees native resources associated with this object */
    public void dispose()
    {
        try {
            super.dispose();
        } finally {
            synchronized(WeibullDist.class) {
                sInstances.remove(this);
            }
        }
    }
  
    /**
     * Invokes the first m-function specified by MCC, with any arguments given on
     * the command line, and prints the result.
     */
    public static void main (String[] args)
    {
        try {
            MWMCR mcr = WeibullMCRFactory.newInstance();
            mcr.runMain( sWblcdfSignature, args);
            mcr.dispose();
        } catch (Throwable t) {
            t.printStackTrace();
        }
    }
    
    /**
     * Calls dispose method for each outstanding instance of this class.
     */
    public static void disposeAllInstances()
    {
        synchronized(WeibullDist.class) {
            for (Disposable i : sInstances) i.dispose();
            sInstances.clear();
        }
    }

    /**
     * Provides the interface for calling the <code>wblcdf</code> M-function 
     * where the first input, an instance of List, receives the output of the M-function and
     * the second input, also an instance of List, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLCDF Weibull cumulative distribution function (cdf).
     * %   P = WBLCDF(X,A,B) returns the cdf of the Weibull distribution
     * %   with scale parameter A and shape parameter B, evaluated at the
     * %   values in X.  The size of P is the common size of the input arguments.
     * %   A scalar input functions as a constant matrix of the same size as the
     * %   other inputs.
     * %
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [P,PLO,PUP] = WBLCDF(X,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for P when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  PLO and PUP are arrays of the same
     * %   size as P containing the lower and upper confidence bounds.
     * %
     * %   See also CDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT.
     * </pre>
     * </p>
     * @param lhs List in which to return outputs. Number of outputs (nargout) is
     * determined by allocated size of this List. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs List containing inputs. Number of inputs (nargin) is determined
     * by the allocated size of this List. Input arguments may be passed as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or
     * as arrays of any supported Java type. Arguments passed as Java types are
     * converted to MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblcdf(List lhs, List rhs) throws MWException
    {
        fMCR.invoke(lhs, rhs, sWblcdfSignature);
    }

    /**
     * Provides the interface for calling the <code>wblcdf</code> M-function 
     * where the first input, an Object array, receives the output of the M-function and
     * the second input, also an Object array, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLCDF Weibull cumulative distribution function (cdf).
     * %   P = WBLCDF(X,A,B) returns the cdf of the Weibull distribution
     * %   with scale parameter A and shape parameter B, evaluated at the
     * %   values in X.  The size of P is the common size of the input arguments.
     * %   A scalar input functions as a constant matrix of the same size as the
     * %   other inputs.
     * %
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [P,PLO,PUP] = WBLCDF(X,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for P when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  PLO and PUP are arrays of the same
     * %   size as P containing the lower and upper confidence bounds.
     * %
     * %   See also CDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT.
     * </pre>
     * </p>
     * @param lhs array in which to return outputs. Number of outputs (nargout)
     * is determined by allocated size of this array. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs array containing inputs. Number of inputs (nargin) is
     * determined by the allocated size of this array. Input arguments may be
     * passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblcdf(Object[] lhs, Object[] rhs) throws MWException
    {
        fMCR.invoke(Arrays.asList(lhs), Arrays.asList(rhs), sWblcdfSignature);
    }

    /**
     * Provides the standard interface for calling the <code>wblcdf</code>
     * M-function with 5 input arguments.
     * Input arguments may be passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     *
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLCDF Weibull cumulative distribution function (cdf).
     * %   P = WBLCDF(X,A,B) returns the cdf of the Weibull distribution
     * %   with scale parameter A and shape parameter B, evaluated at the
     * %   values in X.  The size of P is the common size of the input arguments.
     * %   A scalar input functions as a constant matrix of the same size as the
     * %   other inputs.
     * %
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [P,PLO,PUP] = WBLCDF(X,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for P when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  PLO and PUP are arrays of the same
     * %   size as P containing the lower and upper confidence bounds.
     * %
     * %   See also CDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT.
     * </pre>
     * </p>
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     * @return Array of length nargout containing the function outputs. Outputs
     * are returned as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>. Each output array
     * should be freed by calling its <code>dispose()</code> method.
     * @throws MWException An error has occurred during the function call.
     */
    public Object[] wblcdf(int nargout, Object... rhs) throws MWException
    {
        Object[] lhs = new Object[nargout];
        fMCR.invoke(Arrays.asList(lhs), 
                    MWMCR.getRhsCompat(rhs, sWblcdfSignature), 
                    sWblcdfSignature);
        return lhs;
    }
    /**
     * Provides the interface for calling the <code>wblfit</code> M-function 
     * where the first input, an instance of List, receives the output of the M-function and
     * the second input, also an instance of List, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLFIT Parameter estimates and confidence intervals for Weibull data.
     * %   PARMHAT = WBLFIT(X) returns maximum likelihood estimates of the
     * %   parameters of the Weibull distribution given the data in X.  PARMHAT(1)
     * %   is the scale parameter, A, and PARMHAT(2) is the shape parameter, B.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X) returns 95% confidence intervals for the
     * %   parameter estimates.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X,ALPHA) returns 100(1-ALPHA) percent
     * %   confidence intervals for the parameter estimates.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING) accepts a boolean vector of the same
     * %   size as X that is 1 for observations that are right-censored and 0 for
     * %   observations that are observed exactly.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ) accepts a frequency vector of
     * %   the same size as X.  FREQ typically contains integer frequencies for
     * %   the corresponding elements in X, but may contain any non-integer
     * %   non-negative values.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ,OPTIONS) specifies control
     * %   parameters for the iterative algorithm used to compute ML estimates.
     * %   This argument can be created by a call to STATSET.  See STATSET('wblfit')
     * %   for parameter names and default values.
     * %
     * %   Pass in [] for ALPHA, CENSORING, or FREQ to use their default values.
     * %
     * %   See also WBLCDF, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, MLE,
     * %   STATSET.
     * </pre>
     * </p>
     * @param lhs List in which to return outputs. Number of outputs (nargout) is
     * determined by allocated size of this List. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs List containing inputs. Number of inputs (nargin) is determined
     * by the allocated size of this List. Input arguments may be passed as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or
     * as arrays of any supported Java type. Arguments passed as Java types are
     * converted to MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblfit(List lhs, List rhs) throws MWException
    {
        fMCR.invoke(lhs, rhs, sWblfitSignature);
    }

    /**
     * Provides the interface for calling the <code>wblfit</code> M-function 
     * where the first input, an Object array, receives the output of the M-function and
     * the second input, also an Object array, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLFIT Parameter estimates and confidence intervals for Weibull data.
     * %   PARMHAT = WBLFIT(X) returns maximum likelihood estimates of the
     * %   parameters of the Weibull distribution given the data in X.  PARMHAT(1)
     * %   is the scale parameter, A, and PARMHAT(2) is the shape parameter, B.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X) returns 95% confidence intervals for the
     * %   parameter estimates.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X,ALPHA) returns 100(1-ALPHA) percent
     * %   confidence intervals for the parameter estimates.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING) accepts a boolean vector of the same
     * %   size as X that is 1 for observations that are right-censored and 0 for
     * %   observations that are observed exactly.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ) accepts a frequency vector of
     * %   the same size as X.  FREQ typically contains integer frequencies for
     * %   the corresponding elements in X, but may contain any non-integer
     * %   non-negative values.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ,OPTIONS) specifies control
     * %   parameters for the iterative algorithm used to compute ML estimates.
     * %   This argument can be created by a call to STATSET.  See STATSET('wblfit')
     * %   for parameter names and default values.
     * %
     * %   Pass in [] for ALPHA, CENSORING, or FREQ to use their default values.
     * %
     * %   See also WBLCDF, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, MLE,
     * %   STATSET.
     * </pre>
     * </p>
     * @param lhs array in which to return outputs. Number of outputs (nargout)
     * is determined by allocated size of this array. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs array containing inputs. Number of inputs (nargin) is
     * determined by the allocated size of this array. Input arguments may be
     * passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblfit(Object[] lhs, Object[] rhs) throws MWException
    {
        fMCR.invoke(Arrays.asList(lhs), Arrays.asList(rhs), sWblfitSignature);
    }

    /**
     * Provides the standard interface for calling the <code>wblfit</code>
     * M-function with 5 input arguments.
     * Input arguments may be passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     *
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLFIT Parameter estimates and confidence intervals for Weibull data.
     * %   PARMHAT = WBLFIT(X) returns maximum likelihood estimates of the
     * %   parameters of the Weibull distribution given the data in X.  PARMHAT(1)
     * %   is the scale parameter, A, and PARMHAT(2) is the shape parameter, B.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X) returns 95% confidence intervals for the
     * %   parameter estimates.
     * %
     * %   [PARMHAT,PARMCI] = WBLFIT(X,ALPHA) returns 100(1-ALPHA) percent
     * %   confidence intervals for the parameter estimates.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING) accepts a boolean vector of the same
     * %   size as X that is 1 for observations that are right-censored and 0 for
     * %   observations that are observed exactly.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ) accepts a frequency vector of
     * %   the same size as X.  FREQ typically contains integer frequencies for
     * %   the corresponding elements in X, but may contain any non-integer
     * %   non-negative values.
     * %
     * %   [...] = WBLFIT(X,ALPHA,CENSORING,FREQ,OPTIONS) specifies control
     * %   parameters for the iterative algorithm used to compute ML estimates.
     * %   This argument can be created by a call to STATSET.  See STATSET('wblfit')
     * %   for parameter names and default values.
     * %
     * %   Pass in [] for ALPHA, CENSORING, or FREQ to use their default values.
     * %
     * %   See also WBLCDF, WBLINV, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, MLE,
     * %   STATSET.
     * </pre>
     * </p>
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     * @return Array of length nargout containing the function outputs. Outputs
     * are returned as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>. Each output array
     * should be freed by calling its <code>dispose()</code> method.
     * @throws MWException An error has occurred during the function call.
     */
    public Object[] wblfit(int nargout, Object... rhs) throws MWException
    {
        Object[] lhs = new Object[nargout];
        fMCR.invoke(Arrays.asList(lhs), 
                    MWMCR.getRhsCompat(rhs, sWblfitSignature), 
                    sWblfitSignature);
        return lhs;
    }
    /**
     * Provides the interface for calling the <code>wblinv</code> M-function 
     * where the first input, an instance of List, receives the output of the M-function and
     * the second input, also an instance of List, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLINV Inverse of the Weibull cumulative distribution function (cdf).
     * %   X = WBLINV(P,A,B) returns the inverse cdf for a Weibull
     * %   distribution with scale parameter A and shape parameter B,
     * %   evaluated at the values in P.  The size of X is the common size of the
     * %   input arguments.  A scalar input functions as a constant matrix of the
     * %   same size as the other inputs.
     * %   
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [X,XLO,XUP] = WBLINV(P,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for X when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  XLO and XUP are arrays of the same
     * %   size as X containing the lower and upper confidence bounds.
     * %
     * %   See also WBLCDF, WBLFIT, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, ICDF.
     * </pre>
     * </p>
     * @param lhs List in which to return outputs. Number of outputs (nargout) is
     * determined by allocated size of this List. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs List containing inputs. Number of inputs (nargin) is determined
     * by the allocated size of this List. Input arguments may be passed as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or
     * as arrays of any supported Java type. Arguments passed as Java types are
     * converted to MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblinv(List lhs, List rhs) throws MWException
    {
        fMCR.invoke(lhs, rhs, sWblinvSignature);
    }

    /**
     * Provides the interface for calling the <code>wblinv</code> M-function 
     * where the first input, an Object array, receives the output of the M-function and
     * the second input, also an Object array, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLINV Inverse of the Weibull cumulative distribution function (cdf).
     * %   X = WBLINV(P,A,B) returns the inverse cdf for a Weibull
     * %   distribution with scale parameter A and shape parameter B,
     * %   evaluated at the values in P.  The size of X is the common size of the
     * %   input arguments.  A scalar input functions as a constant matrix of the
     * %   same size as the other inputs.
     * %   
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [X,XLO,XUP] = WBLINV(P,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for X when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  XLO and XUP are arrays of the same
     * %   size as X containing the lower and upper confidence bounds.
     * %
     * %   See also WBLCDF, WBLFIT, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, ICDF.
     * </pre>
     * </p>
     * @param lhs array in which to return outputs. Number of outputs (nargout)
     * is determined by allocated size of this array. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs array containing inputs. Number of inputs (nargin) is
     * determined by the allocated size of this array. Input arguments may be
     * passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblinv(Object[] lhs, Object[] rhs) throws MWException
    {
        fMCR.invoke(Arrays.asList(lhs), Arrays.asList(rhs), sWblinvSignature);
    }

    /**
     * Provides the standard interface for calling the <code>wblinv</code>
     * M-function with 5 input arguments.
     * Input arguments may be passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     *
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLINV Inverse of the Weibull cumulative distribution function (cdf).
     * %   X = WBLINV(P,A,B) returns the inverse cdf for a Weibull
     * %   distribution with scale parameter A and shape parameter B,
     * %   evaluated at the values in P.  The size of X is the common size of the
     * %   input arguments.  A scalar input functions as a constant matrix of the
     * %   same size as the other inputs.
     * %   
     * %   Default values for A and B are 1 and 1, respectively.
     * %
     * %   [X,XLO,XUP] = WBLINV(P,A,B,PCOV,ALPHA) produces confidence
     * %   bounds for X when the input parameters A and B are estimates.
     * %   PCOV is a 2-by-2 matrix containing the covariance matrix of the estimated
     * %   parameters.  ALPHA has a default value of 0.05, and specifies
     * %   100*(1-ALPHA)% confidence bounds.  XLO and XUP are arrays of the same
     * %   size as X containing the lower and upper confidence bounds.
     * %
     * %   See also WBLCDF, WBLFIT, WBLLIKE, WBLPDF, WBLRND, WBLSTAT, ICDF.
     * </pre>
     * </p>
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     * @return Array of length nargout containing the function outputs. Outputs
     * are returned as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>. Each output array
     * should be freed by calling its <code>dispose()</code> method.
     * @throws MWException An error has occurred during the function call.
     */
    public Object[] wblinv(int nargout, Object... rhs) throws MWException
    {
        Object[] lhs = new Object[nargout];
        fMCR.invoke(Arrays.asList(lhs), 
                    MWMCR.getRhsCompat(rhs, sWblinvSignature), 
                    sWblinvSignature);
        return lhs;
    }
    /**
     * Provides the interface for calling the <code>wblrnd</code> M-function 
     * where the first input, an instance of List, receives the output of the M-function and
     * the second input, also an instance of List, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLRND Random arrays from the Weibull distribution.
     * %   R = WBLRND(A,B) returns an array of random numbers chosen from the
     * %   Weibull distribution with scale parameter A and shape parameter B.  The
     * %   size of R is the common size of A and B if both are arrays.  If either
     * %   parameter is a scalar, the size of R is the size of the other
     * %   parameter.
     * %
     * %   R = WBLRND(A,B,M,N,...) or  R = WBLRND(A,B,[M,N,...]) returns an
     * %   M-by-N-by-... array.
     * %
     * %   See also WBLCDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLSTAT, RANDOM.
     * </pre>
     * </p>
     * @param lhs List in which to return outputs. Number of outputs (nargout) is
     * determined by allocated size of this List. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs List containing inputs. Number of inputs (nargin) is determined
     * by the allocated size of this List. Input arguments may be passed as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or
     * as arrays of any supported Java type. Arguments passed as Java types are
     * converted to MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblrnd(List lhs, List rhs) throws MWException
    {
        fMCR.invoke(lhs, rhs, sWblrndSignature);
    }

    /**
     * Provides the interface for calling the <code>wblrnd</code> M-function 
     * where the first input, an Object array, receives the output of the M-function and
     * the second input, also an Object array, provides the input to the M-function.
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLRND Random arrays from the Weibull distribution.
     * %   R = WBLRND(A,B) returns an array of random numbers chosen from the
     * %   Weibull distribution with scale parameter A and shape parameter B.  The
     * %   size of R is the common size of A and B if both are arrays.  If either
     * %   parameter is a scalar, the size of R is the size of the other
     * %   parameter.
     * %
     * %   R = WBLRND(A,B,M,N,...) or  R = WBLRND(A,B,[M,N,...]) returns an
     * %   M-by-N-by-... array.
     * %
     * %   See also WBLCDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLSTAT, RANDOM.
     * </pre>
     * </p>
     * @param lhs array in which to return outputs. Number of outputs (nargout)
     * is determined by allocated size of this array. Outputs are returned as
     * sub-classes of <code>com.mathworks.toolbox.javabuilder.MWArray</code>.
     * Each output array should be freed by calling its <code>dispose()</code>
     * method.
     *
     * @param rhs array containing inputs. Number of inputs (nargin) is
     * determined by the allocated size of this array. Input arguments may be
     * passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     * @throws MWException An error has occurred during the function call.
     */
    public void wblrnd(Object[] lhs, Object[] rhs) throws MWException
    {
        fMCR.invoke(Arrays.asList(lhs), Arrays.asList(rhs), sWblrndSignature);
    }

    /**
     * Provides the standard interface for calling the <code>wblrnd</code>
     * M-function with 3 input arguments.
     * Input arguments may be passed as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>, or as arrays of
     * any supported Java type. Arguments passed as Java types are converted to
     * MATLAB arrays according to default conversion rules.
     *
     * <p>M-documentation as provided by the author of the M function:
     * <pre>
     * %WBLRND Random arrays from the Weibull distribution.
     * %   R = WBLRND(A,B) returns an array of random numbers chosen from the
     * %   Weibull distribution with scale parameter A and shape parameter B.  The
     * %   size of R is the common size of A and B if both are arrays.  If either
     * %   parameter is a scalar, the size of R is the size of the other
     * %   parameter.
     * %
     * %   R = WBLRND(A,B,M,N,...) or  R = WBLRND(A,B,[M,N,...]) returns an
     * %   M-by-N-by-... array.
     * %
     * %   See also WBLCDF, WBLFIT, WBLINV, WBLLIKE, WBLPDF, WBLSTAT, RANDOM.
     * </pre>
     * </p>
     * @param nargout Number of outputs to return.
     * @param rhs The inputs to the M function.
     * @return Array of length nargout containing the function outputs. Outputs
     * are returned as sub-classes of
     * <code>com.mathworks.toolbox.javabuilder.MWArray</code>. Each output array
     * should be freed by calling its <code>dispose()</code> method.
     * @throws MWException An error has occurred during the function call.
     */
    public Object[] wblrnd(int nargout, Object... rhs) throws MWException
    {
        Object[] lhs = new Object[nargout];
        fMCR.invoke(Arrays.asList(lhs), 
                    MWMCR.getRhsCompat(rhs, sWblrndSignature), 
                    sWblrndSignature);
        return lhs;
    }
}
