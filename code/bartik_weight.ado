
program define bartik_weight, rclass
	syntax [if] [in], z(varlist) weightstub(varlist)  y(varname) x(varname) [absorb(varname)] [controls(varlist)] [weight_var(varname)]
    if "`weight_var'" != "" {
        local weight_command "[aweight=`weight_var']"
    }
    local share_stub `sharestub'
	local weight_stub `weightstub'
	local x `x'
	local y `y'
	disp "Controls: `controls'"
	disp "X variable is `x'"
	disp "Y variable is `y'"
    if "`by'" == "" {
        tempvar by_var
		gen `by_var' = 1
    }
    else {
        tempvar by_var
		gen `by_var' = `by'
        }
	if "`absorb'" != "" {
		disp "Absorbing `absorb'"
        tempname abs
        qui tab `absorb', gen(`abs'_)
        drop `abs'_1
        local absorb_var `abs'_*
        local controls "`controls' `absorb_var'"
    }
	else {
		tempvar absorb_var
		gen `absorb_var' = 1
		local absorb_command  "absorb(`absorb_var')"
		}
    preserve
    collapse (first) `weight_stub', by(year)
    foreach var of varlist `weight_stub' {
        qui replace `var' = 0 if `var' == .
    }
    tempname g
    mkmat `weight_stub', mat(`g')
    restore
    /* _rmcoll `z', forcedrop  */
    /* local z = r(varlist) */
    mata: weights("`y'", "`x'", "`z'", "`controls'", "`weight_var'", "`g'")
    mat alpha = r(alpha)
    mat beta = r(beta)
    mat G = r(G)
    return matrix alpha = alpha
    return matrix beta = beta
    return matrix G = G
end

mata:
	void weights(string scalar yname, string scalar xname, string scalar Zname, string scalar Wname, string scalar weightname, string scalar Gname)
    {
        G = st_matrix(Gname)
        G = rowshape(G, 1)'
		x = st_data(., xname)
		Z = st_data(., tokens(Zname))
		y = st_data(., yname)
		xbar = st_data(., (yname,xname) )
		W = st_data(., tokens(Wname))
		weight = diag(st_data(., weightname))
		n = rows(x)
		K = cols(Z)
		/** Adding ones **/
		WW = W, J(n,1,1)
		M_W = I(n) - WW*cholinv(WW'*weight*WW)*WW'*weight
		
		ZZ = M_W*Z
		xx = M_W*x
		yy = M_W*y

        alpha = (diag(G) * Z' * weight* xx) / (G' * Z' * weight* xx)
        beta = (Z' * weight* yy) :/ (Z' * weight* xx)
        st_matrix("r(alpha)", alpha)
        st_matrix("r(beta)", beta)
        st_matrix("r(G)", G)
    }
end        