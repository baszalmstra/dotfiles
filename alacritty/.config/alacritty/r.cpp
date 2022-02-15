struct MyFunctionOne {
    void configure_inputs(InputBuilder& builder) const {
        builder.add<int>("a");
        builder.add<int>("b");
    }

    void configure_outputs(OutputBuilder& builder) const {
        builder.add<int>("result");
    }

    void process(const Inputs &inputs, Outputs& output) const {
        int a = inputs.get<int>("a");
        int b = inputs.get<int>("b");
        output.set<int>("result", a+b);
    }
}

MyFunctionOne GLOBAL_DING;

// Define a pipeline
Pipeline pipeline;
auto a = pipeline.add<MyFunctionOne>();
auto b = pipeline.add([](int a, int b) { std::cout << "Done"; })
pipeline.connect(a,b)

// Open the GUI
PipelineInputs inputs;
inputs.add("input", 3);

visualize(pipeline);

// Run the execution
Executor executor;
Timeline timeline = executor.execute(pipeline);

while(!timeline.is_done(b)) {
    ;
}




