extends GdUnitTestSuite

func test_hello_world():
        assert_str("hello").is_equal("hello")

func after_test():
    # Clean up any nodes you created
    pass