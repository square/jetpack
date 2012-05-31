package jetpack.filter;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class IgnoreUnknownHttpMethodsFilter implements Filter {

    java.util.List<String> allowedMethodList;

    public void init(FilterConfig filterConfig) throws ServletException {
        allowedMethodList = new java.util.ArrayList<String>();
        allowedMethodList.add("GET");
        allowedMethodList.add("PUT");
        allowedMethodList.add("DELETE");
        allowedMethodList.add("POST");
        allowedMethodList.add("HEAD");
    }

    public void destroy() {
        allowedMethodList = null;
    }

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest)request;

        if ( allowedMethodList.contains(req.getMethod()) ) {
          chain.doFilter(request, response);
        } else {
          HttpServletResponse res = (HttpServletResponse)response;
          res.sendError(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
          return;
        }
    }
}