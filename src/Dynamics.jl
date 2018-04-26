module Dynamics
    using VoteNetworks.World
    using MetaGraphs
    using LightGraphs

    struct aDynamics
        probabilities_to_be_called
        function_to_call::Function
        meth::Symbol
        limit::Int64
    end

    function newDynamics(function_to_call; method = :poll, limit = 1, probabilities_to_be_called = :nothing)
        if probabilities_to_be_called == :nothing
            probabilities_to_be_called = ones(1)
        end
        return aDynamics(probabilities_to_be_called, function_to_call, method, limit)
    end

    function apply_dynamics(world, dynamics)
        if dynamics.probabilities_to_be_called == [1]
            dynamics.probabilities_to_be_called = ones(LightGraphs.nv(world.network))
        end
        new_world = world
        ii = 1
        for node in LightGraphs.vertices(world.network)
            if rand() <= dynamics.probabilities_to_be_called[ii]
                neighborhood = gen_neighborhood(world.network, node, dynamics.limit)
                node_preferences = MetaGraphs.get_prop(world.network, node, :preferences)
                node_beliefs = MetaGraphs.get_prop(world.network, node, :beliefs)
                node_attributes = MetaGraphs.get_prop(world.network, node, :attributes)
                neighbors_preferences = Dict()
                neighbors_beliefs = Dict()
                neighbors_attributes = Dict()
                for neighbor in neighborhood
                    neighbors_preferences[neighbor] = MetaGraphs.get_prop(world.network, neighbor, :preferences)
                    neighbors_beliefs[neighbor] = MetaGraphs.get_prop(world.network, neighbor, :beliefs)
                    neighbors_attributes[neighbor] = MetaGraphs.get_prop(world.network, neighbor, :attributes)
                end
                response = dynamics.function_to_call(node_preferences, node_beliefs, node_attributes, neighbors_preferences, neighbors_beliefs, neighbors_attributes)
                if dynamics.meth == :poll
                    new_network = World.update_node(new_world, node, response[1], response[2], response[3])
                    new_world = World.VotingWorld(new_network, new_world.parties, new_world.preference_range)
                elseif dynamics.meth == :cast
                    for neighbor in neighborhood
                        if neighbor in keys(response[1])
                            new_network = World.update_node(new_world, neighbor, response[1][neighbor], response[2][neighbor], response[3][neighbor])
                            new_world = World.VotingWorld(new_network, new_world.parties, new_world.preference_range)
                        end
                    end
                end
            end
            ii = ii+1
        end
        return new_world
    end

    function apply_dynamics(world, dynamics, n_iter::Int64)
        new_world = world
        for ii = 1:n_iter
            new_world = apply_dynamics(world, dynamics)
        end
        return new_world
    end

    function gen_neighborhood(network, init_node, limit)
        ii = limit
        list_neighbors = [init_node]
        while ii != 0
            for node in list_neighbors
                list_neighbors = unique(vcat(list_neighbors, LightGraphs.neighbors(network,node)))
            end
            ii = ii-1
        end
        list_neighbors = filter(n -> n ≠ init_node, list_neighbors)
        return list_neighbors
    end
end #Dynamics
