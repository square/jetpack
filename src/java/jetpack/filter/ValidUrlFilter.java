package jetpack.filter;

import java.io.IOException;
import java.util.regex.Pattern;
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

        String requestUrl = req.getRequestURL().toString();
        String queryString = req.getQueryString();
        if (queryString != null) {
            requestUrl += "?" + queryString;
        }

        if (urlValidator.isValid(requestUrl) && isValidQuery(queryString)) {
           chain.doFilter(request, response);
        } else {
           HttpServletResponse res = (HttpServletResponse)response;
           res.sendError(HttpServletResponse.SC_BAD_REQUEST);
           return;
        }
    }

    // commons validator allows any character in query string, we want to restrict it a bit
    // and not allow unescaped angle brackets for example.
    private static final String QUERY_REGEX = "^([-\\w:@&=~+,.!*'%$_;\\(\\)]*)$";
    private static final Pattern QUERY_PATTERN = Pattern.compile(QUERY_REGEX);

    protected boolean isValidQuery(String query) {
        if (query == null) {
            return true;
        }

        return QUERY_PATTERN.matcher(query).matches();
    }
}
