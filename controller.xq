xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $allowOrigin := "*";

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>

else if ($exist:path eq "/") then
    (: forward root path to index.xql :)
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="index.html"/>
    </dispatch>

else if (matches($exist:path, "\.(json|js|md|png|svg)$", "s")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/{$exist:path}"/>
    </dispatch>

(: all other requests are passed on the Open API router :)
else
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/modules/api.xq">
            <set-header name="Access-Control-Allow-Origin" value="{$allowOrigin}"/>
            { if ($allowOrigin = "*") then () else <set-header name="Access-Control-Allow-Credentials" value="true"/> }
            <set-header name="Access-Control-Allow-Methods" value="GET, POST, DELETE, PUT, PATCH, OPTIONS"/>
            <set-header name="Access-Control-Allow-Headers" value="Content-Type, api_key, Authorization"/>
            <set-header name="Access-Control-Expose-Headers" value="pb-start, pb-total"/>
        </forward>
    </dispatch>
