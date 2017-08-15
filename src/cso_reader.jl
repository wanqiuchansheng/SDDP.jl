function gettransitionmatrix(m)
    stage = zeros(Int, length(m.subproblems))
    P = zeros(length(m.subproblems), length(m.subproblems))
    stage[1] = 1
    for (i, sp) in enumerate(m.subproblems)
        for (child, probability) in zip(sp.children, sp.children_probability)
            child_idx = findfirst(m.subproblems, child)
            if stage[child_idx] != 0 && stage[child_idx] != stage[i] + 1
                error("Graph structure not supported. SDDP.jl only supports a regular lattice.")
            end
            stage[child_idx] = stage[i] + 1
            P[i, child_idx] = probability
        end
    end
    nstages = maximum(stage)
    Transition = Array{Float64, 2}[ [1.0]' ]
    mapping = Vector{Int}[[1]]
    for t in 2:nstages
        push!(mapping, Int[])
        last_idxs = (1:length(m.subproblems))[stage .== (t-1)]
        idxs = (1:length(m.subproblems))[stage .== t]
        for i in idxs
            push!(mapping[t], i)
        end
        T = zeros(length(last_idxs), length(idxs))
        for (row, i) in enumerate(last_idxs)
            for (col, j) in enumerate(idxs)
                T[row, col] = P[i, j]
            end
        end
        push!(Transition, T)
    end
    Transition, mapping
end

function SDDPModel(filename::String;
    objective_bound      = nothing,
    risk_measure::AbstractRiskMeasure = Expectation(),
    cut_oracle::AbstractCutOracle = DefaultCutOracle(),
    solver::JuMP.MathProgBase.AbstractMathProgSolver = UnsetSolver(),
    value_function       = DefaultValueFunction(cut_oracle),
    )

    m = CSO.read(filename)
    T, mapping = gettransitionmatrix(m)


    function build(sp, t, i)
        subproblem = m.subproblems[mapping[t][i]]
        realization = subproblem.realisations[1]
        x = @variable(sp, [i=1:length(realization.collb)], lowerbound=realization.collb[i], upperbound=realization.colub[i])
        for (idx, (i, j)) in enumerate(zip(realization.states_in, realization.states_out))
            xin_idx = findfirst(realization.colnames, i)
            xout_idx = findfirst(realization.colnames, j)
            sp.colVal[x[xout_idx].col] = m.states[idx]
            statevariable!(sp, x[xin_idx], x[xout_idx])
        end
        sp.colCat = copy(realization.colcat)
        stageobjective!(sp, dot(realization.c, x))
        for (row, (rowlb, rowub)) in enumerate(zip(realization.rowlb, realization.rowub))
            if rowlb == -Inf
                @constraint(sp, dot(realization.A[row, :], x) <= rowub)
            elseif rowub == Inf
                @constraint(sp, dot(realization.A[row, :], x) >= rowlb)
            elseif rowlb == rowub
                @constraint(sp, dot(realization.A[row, :], x) == rowlb)
            else
                @constraint(sp, rowlb <= dot(realization.A[row, :], x) <= rowub)
            end
        end
    end

    SDDPModel(build;
        sense                = :Max,
        stages               = length(T),
        objective_bound      = objective_bound,
        markov_transition    = T,
        risk_measure         = risk_measure,
        cut_oracle           = cut_oracle,
        solver               = solver,
        value_function       = value_function,
    )
end
