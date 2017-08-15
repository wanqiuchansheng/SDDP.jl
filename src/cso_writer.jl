# TODO quadratic objective
# TODO constant in objective
using CSO
function writecso{T}(filename::String, m::SDDPModel{DefaultValueFunction{T}}, writelp=true; kwargs...)
    model = CSO.CSOProblem{CSO.LinearSubproblemRealisation}(
        CSO.CSOSubproblem{CSO.LinearSubproblemRealisation}[],
        [getvalue(s.incoming) for s in states(getsubproblem(m, 1, 1))]
    )
    for stage in stages(m)
        n = length(model.subproblems) - size(stage.transitionprobabilities, 1)
        for sp in subproblems(stage)
            subproblem = CSO.CSOSubproblem()
            ex = ext(sp)
            t = ex.stage
            i = ex.markovstate
            if t > 1
                for prior_idx in 1:size(stage.transitionprobabilities, 1)
                    prob = stage.transitionprobabilities[prior_idx, i]
                    push!(model.subproblems[n + prior_idx].children, subproblem)
                    push!(model.subproblems[n + prior_idx].children_probability, prob)
                end
            end
            if hasnoises(sp)
                for (noise, probability) in zip(ex.noises, ex.noiseprobability)
                    setnoise!(sp, noise)
                    push!(subproblem.realisations, construct_realisation(sp))
                    push!(subproblem.realisation_probabilities, probability)
                end
            else
                push!(subproblem.realisations, construct_realisation(sp))
                push!(subproblem.realisation_probabilities, 1.0)
            end
            push!(model.subproblems, subproblem)
        end
    end
    CSO.write(filename, model; writelp=writelp, kwargs...)
end

function construct_realisation(sp)
    JuMP.build(sp)
    constraint_bounds = JuMP.constraintbounds(sp)
    colnames = ["V$(i)" for i in 1:JuMP.MathProgBase.numvar(sp)]
    for (i, name) in enumerate(sp.colNames)
        if name != "" && name != "__anon__"
            colnames[i] = name
        end
    end
    c = zeros(Float64, JuMP.MathProgBase.numvar(sp))
    obj = JuMP.getobjective(sp).aff
    for (coef, var) in zip(obj.coeffs, obj.vars)
        c[var.col] += coef
    end
    ex = ext(sp)
    theta_idx = ex.valueoracle.theta.col
    good_cols = vcat(1:(theta_idx-1), (theta_idx+1):length(c))
    s_out = [colnames[s.variable.col] for s in ex.states]
    s_in = [colnames[sp.linconstr[s.constraint.idx].terms.vars[1].col] for s in ex.states]
    bad_rows = [s.constraint.idx for s in ex.states]
    for (i, con) in enumerate(sp.linconstr)
        for v in con.terms.vars
            if v.col == theta_idx
                push!(bad_rows, i)
                continue
            end
        end
    end
    good_rows = [i for i in 1:JuMP.MathProgBase.numconstr(sp) if !(i in bad_rows)]
    CSO.LinearSubproblemRealisation(
        JuMP.MathProgBase.getconstrmatrix(internalmodel(sp))[good_rows, good_cols],
        sp.colLower[good_cols],
        sp.colUpper[good_cols],
        c[good_cols],
        constraint_bounds[1][good_rows],
        constraint_bounds[2][good_rows],
        JuMP.getobjectivesense(sp),
        sp.colCat[good_cols],
        colnames[good_cols],
        s_in,
        s_out
    )
end
