from pomegranate import DiscreteDistribution, ConditionalProbabilityTable, Node, BayesianNetwork

def generate_model():
    wind_speed = DiscreteDistribution({'P': 0.75, 'F':0.25})
    wind_direction = DiscreteDistribution({'P':0.72, 'F':0.25})
    wind_dir_cpd = ConditionalProbabilityTable([['P', 'P', 0.0],
                                                ['F', 'P', 0.5],
                                                ['P', 'F', 0.5],
                                                ['F', 'F', 1.0]], [wind_direction])
    wind_speed_cpd = ConditionalProbabilityTable([['P', 'P', 0.0],
                                                 ['F', 'P', 0.5],
                                                 ['P', 'F', 0.5],
                                                 ['F', 'F', 1.0]], [wind_speed])
    s1 = Node(wind_speed_cpd, name='wind speed')
    s2 = Node(wind_direction_, name='wind direction')
    s3 = Node(wind_condition, name='wind condition')
    model = BayesianNetwork("Wind condition failure model")
    model.add_states(s1, s2, s3)
    model.add_edge(s1, s3)
    model.add_edge(s2, s3)
    model.bake()
    return model



if __name__ == '__main__':
    m = generate_model()
    print(m)