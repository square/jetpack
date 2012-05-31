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
import org.apache.commons.validator.routines.RegexValidator;
import org.apache.commons.validator.routines.UrlValidator;

public class ValidUrlFilter implements Filter {

    UrlValidator urlValidator;

    public void init(FilterConfig filterConfig) throws ServletException {
        String[] schemes = {"http","https"};
        RegexValidator authorityValidator = new RegexValidator("^([\\p{Alnum}\\-\\.]*)(:\\d*)?(.*)?", false);
        urlValidator = new UrlValidator(schemes, authorityValidator, UrlValidator.ALLOW_LOCAL_URLS);
    }

    public void destroy() {
        urlValidator = null;
    }

    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest)request;

        if (urlValidator.isValid(req.getRequestURL().toString())) {
           chain.doFilter(request, response);
        } else {
           HttpServletResponse res = (HttpServletResponse)response;
           res.sendError(HttpServletResponse.SC_BAD_REQUEST);
           return;
        }
    }
}
