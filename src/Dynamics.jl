module Dynamics
    using VoteNetworks.World
    using MetaGraphs
    using LightGraphs

    struct aDynamics
        probabilities_to_be_called::Array
        function_to_call::Function
        meth::Symbol
        limit::Int64
    end

    function newDynamics(function_to_call, method = :poll, limit = 1, probabilities_to_be_called = :nothing)
        if probabilities_to_be_called == :nothing
            probabilities_to_be_called = ones(1)
        end
        return aDynamics(probabilities_to_be_call, function_to_call, method, limit)
    end

    function apply_dynamics(world::VotingWorld, dynamics::aDynamics)
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
                neighbors_preferences = [MetaGraphs.get_prop(world.network, neighbor, :preferences) for neighbor in neighborhood]
                neighbors_beliefs = [MetaGraphs.get_prop(world.network, neighbor, :beliefs) for neighbor in neighborhood]
                neighbors_attributes = [MetaGraphs.get_prop(world.network, neighbor, :attributes) for neighbor in neighborhood]
                response = dynamics.function_to_call(node_preference, node_beliefs, node_attributes, neighbors_preferences, neighbors_beliefs, neighbors_attributes)
                if dynamics.meth == :poll
                    new_network = World.update_node(new_world, node, response[1], response[2], response[3])
                    new_world = World.VotingWorld(new_network, new_world.parties, new_world.preference_range)
                elseif dynamics.meth == :cast
                    jj = 1
                    for neighbor in neighborhood
                        new_network = World.update_node(new_world, neighbor, response[jj][1], response[jj][2], response[jj][3])
                        new_world = World.VotingWorld(new_network, new_world.parties, new_world.preference_range)
                        jj = jj +1
                    end
                end
            end
            ii = ii+1
        end
    end

    function apply_dynamics(world::VotingWorld, dynamics::aDynamics, n_iter)
        for ii = 1:n_iter
            apply_dynamics(world, dynamics)
        end
    end

    function gen_neighborhood(network, init_node, limit)
        ii = limit
        list_neighbors = [init_node]
        while ii != 0
            for node in list_neighbors
                list_neighbors = unique(vcat(list_neighbors, LightGraphs.neighbors(node)))
            end
            ii = ii-1
        end
        list_neighbors = filter(n -> n ≠ init_node, list_neighbors)
        return list_neighbors
    end
end #Dynamics
