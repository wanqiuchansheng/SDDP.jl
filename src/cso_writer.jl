# TODO drop cuts and theta variable
# TODO drop equality constraint
# TODO quadratic objective
# TODO constant in objective
using CSO
function writecso(filename::String, m::SDDPModel; kwargs...)

    model = CSO.CSOProblem{CSO.LinearSubproblemRealisation}(
        CSO.CSOSubproblem{CSO.LinearSubproblemRealisation}[],
        nstates(getsubproblem(m, 1, 1))
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
    CSO.write(filename, model; kwargs...)
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
    s_in = [s.variable.col for s in ex.states]
    s_out = [sp.linconstr[s.constraint.idx].terms.vars[1].col for s in ex.states]
    CSO.LinearSubproblemRealisation(
        JuMP.MathProgBase.getconstrmatrix(internalmodel(sp)),
        sp.colLower,
        sp.colUpper,
        c,
        constraint_bounds[1],
        constraint_bounds[2],
        JuMP.getobjectivesense(sp),
        sp.colCat,
        colnames,
        s_in,
        s_out
    )
end
