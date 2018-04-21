module World
using MetaGraphs, LightGraphs

export initialize, VotingWorld

struct VotingWorld
    network::MetaGraphs.MetaGraph
    parties::Array{Symbol}
    preference_range::Array{Float64}
end

function initialize(num_voters; parties = [:A, :B], init_preferences = [], init_beliefs=[], network_structure = "barabasi-albert", avg_edges=3, preferences_method="random", preference_order="degree",
    beliefs_order="RandomBeliefs", edges_matrix = [], watts_strogatz_beta=0, preference_range = [0,11,Inf], init_attributes = Dict(), attributes_order= "NoAttributes")
    if isa(parties, Array{String})
        parties = convert(Array{Symbol}, parties)
    end #convert_parties_to_symbols
    network = build_network(num_voters, network_structure, avg_edges, edges_matrix, watts_strogatz_beta)
    network = attach_preferences(network, parties, init_preferences, preferences_method, preference_order, preference_range)
    network = attach_beliefs(network, init_beliefs, beliefs_order, parties)
    network = attach_attributes(network, init_attributes, attributes_order)
    return VotingWorld(network, parties, preference_range);
end #initialize

function build_network(num_voters, network_structure, avg_edges, edges_matrix, watts_strogatz_beta)
    if network_structure =="barabasi-albert"
        graph = LightGraphs.barabasi_albert(num_voters, avg_edges)
    elseif network_structure == "watts_strogatz"
        graph = LightGraphs.watts_strogatz(num_voters, avg_edges, watts_strogatz_beta)
    end #network_structure
    graph = MetaGraphs.MetaGraph(graph)
end #build_network

function attach_preferences(network, parties, init_preferences, preferences_method, preference_order, preference_range, thr_switch = 0, decay="exp")
    num_voters = LightGraphs.nv(network)
    preferences = Array{Dict{Symbol, Int64}}(num_voters)
    #create the initial preference vector
    if length(init_preferences) == num_voters
        preferences = init_preferences
    elseif preferences_method == "random"
        for ii = 1:num_voters
            preference = Dict{Symbol, Int64}()
            for jj in parties
                preference[jj] = floor(rand()*preference_range[2])
            end
            preferences[ii] = preference
        end
    end
    # allow for some randomness if needed
    if thr_switch != 0
        for ii = 1:num_voters
            for jj = ii+1:num_voters
                pref_1 = preferences[ii]
                pref_2 = preferences[jj]
                if decay == "exp"
                    threshold = thr_switch^(ii-jj)
                elseif decay == "lin"
                    threshold = thr_switch/(ii-jj)
                end
                if rand() <= threshold
                    preferences[ii] = pref_2
                    preferences[jj] = pref_1
                    break
                end
            end
        end
    end
    # attach the preferences to the nodes in the network
    if preference_order == "degree"
        preference_list = zip(ordered_nodes_by_degree(network), preferences)
    elseif preference_order == "inversedDegree"
        preference_list = zip(flipdim(ordered_nodes_by_degree(network),1), preferences)
    elseif preference_order == "random"
        node = [node for node in LightGraphs.vertices(network)]
        preference_list = zip(randperm(nodes), preferences)
    end
    for node in preference_list
        MetaGraphs.set_prop!(network, node[1], :preferences, node[2])
    end
    return network
end #attach_preferences

function attach_beliefs(network, init_beliefs, beliefs_order, parties)
    # I'm way too lazy to implement a belief system right now
    num_parties = length(parties)
    if beliefs_order == "RandomBeliefs"
        for node in LightGraphs.vertices(network)
            beliefs_vector = rand(Float64, num_parties)
            beliefs_vector = beliefs_vector./sum(beliefs_vector)
            beliefs = Dict()
            for party in parties
                beliefs[party] = pop!(vec(beliefs_vector))
            end
            MetaGraphs.set_prop!(network, node, :beliefs, beliefs)
        end
    end
    return network
end

function attach_attributes(network, init_attributes, attributes_order)
    # I'm way too lazy to implement a belief system right now
    if attributes_order == "NoAttributes"
        for node in LightGraphs.vertices(network)
            MetaGraphs.set_prop!(network, node, :attributes, Dict())
        end
    end
    return network
end

function ordered_nodes_by_degree(network)
    nodes_degrees = [(node, length(LightGraphs.neighbors(network, node))) for node in LightGraphs.vertices(network)]
    nodes_degrees = sort(nodes_degrees, by=x->x[2], rev=true)
    return [node[1] for node in nodes_degrees]
end #ordered_nodes_by_degree

function update_node(world, node, preferences, beliefs, attributes)
    new_network = world.network
    MetaGraphs.set_prop!(new_network, node, :preferences, preferences)
    MetaGraphs.set_prop!(new_network, node, :beliefs, beliefs)
    MetaGraphs.set_prop!(new_network, node, :attributes, attributes)
    return new_network
end

end #World
