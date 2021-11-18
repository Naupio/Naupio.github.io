---
layout: blog
title: Elixir Style Format Credo
date: 2019-04-28 00:00:00
tags: Elixir
---

### Summary
在开发项目时，为了便于项目代码阅读、分享和团队协作开发，需要相对统一的代码风格和编程规范标准。本文将介绍关于 Elixir 代码格式化工具——**Mix.Tasks.Format**，还有社区里推荐的**代码规范**和基于 **Credo** 工具进行静态代码分析。

---

### MIX Task: Format
基于 `mix new` 初始化的 elixir 项目根目录下都会有一个 `.formatter,exs` 文件，这个文件是 `mix format` 任务的配置文件。  
文件内容类似如下：
```elixir
# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 98,
  rename_deprecated_at: "1.8.1"
]
```

其中：   
- `inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]` 描述的是需要进行格式化的文件名或者模式匹配的文件名。  
- `line_length: 98` 描述每行代码的最大长度。  
- `rename_deprecated_at: "1.8.1"` 描述的是使用 **elixir-1.8.1** 版本中的新接口替换代码中使用了弃用接口的部分。
  
---

<!--more-->

#### 例子  
* 未经格式化之前代码如下：
  ```elixir
  defmodule ElixirStyleFormatCredo do
    @moduledoc """
    Documentation for ElixirStyleFormatCredo.
    """

    def test_format_rename_deprecated do


      Enum.partition([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end)
      Enum.split_with([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end)


    end
  end
  ```
* 运行 `mix format --check-formatted` 检查文件是否已经格式化：
  ```elixir
  ** (Mix) mix format failed due to --check-formatted.
  The following files were not formatted:

    * /elixir_style_format_credo/lib/elixir_style_format_credo.ex
  ```  
从输出结果可以看出初试代码没有格式化过。

* 运行 `mix format --check-equivalent` 检查格式化之后，生成的语法数版本和未格式化之前是否一致：
  ```elixir
  ** (Mix) mix format failed due to --check-equivalent.
  The following files were not equivalent:

    * /elixir_style_format_credo/lib/elixir_style_format_credo.ex

  Please report this bug with the input files at github.com/elixir-lang/elixir/issues
  ```

从输出结果可以看出，格式化之后生成的语法树会不一致。这是因为使用了 `rename_deprecated_at` 配置，导致格式化之后标记为 deprecated 的函数会被新版本替换掉所造成的。  

* 运行 `mix format` 格式化成功之后的代码如下：  
  ```elixir
  defmodule ElixirStyleFormatCredo do
    @moduledoc """
    Documentation for ElixirStyleFormatCredo.
    """

    def test_format_rename_deprecated do
      Enum.split_with([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end)
      Enum.split_with([5, 4, 3, 2, 1, 0], fn x -> rem(x, 2) == 0 end)
    end
  end

  ```
从结果上可以看出弃用的 Enum.partition 被替换成 Enum.split_with，部分多余的空行也被删除了。  

---

### Elixir Code Style
`Mix.Tasks.Format` 可以格式大部分代码的风格规范，但是也有一些编码规范是 `Mix.Tasks.Format` 无法格式化的。  

#### `Mix.Tasks.Format` 可自动格式化的部分
* 避免结尾多余的空格
* 每个文件结束的时候增加一个换行
* Unix-style 风格的换行（ git 用户可以这样配置：`git config --global core.autocrlf true` ）
* 每行长度限制在 **98** 个字符
* 在操作符两边增加空格，在逗号、冒号和分号后面增加空格，不要再各类括号旁边增加无用空格
  ```elixir
  sum = 1 + 2
  {a, b} = {2, 3}
  [first | rest] = [1, 2, 3]
  Enum.map(["one", <<"two">>, "three"], fn num -> IO.puts(num) end)
  ```
* 在范围符号两旁和一元操作符后面不要加空格
  ```elixir
  0 - 1 == -1
  ^pinned = some_func()
  5 in 1..10
  ```
* 使用空行分割多个函数定义之间的逻辑段落
  ```elixir
  def some_function(some_data) do
    some_data |> other_function() |> List.first()
  end

  def some_function do
    result
  end

  def some_other_function do
    another_result
  end

  def a_longer_function do
    one
    two

    three
    four
  end
  ```
* `defmodule` 关键字后面不要增加空行
* 如果函数定义部分和子句 `do:` 太长的话，在 `do:` 子句部分换行
  ```elixir
  def some_function([:foo, :bar, :baz] = args),
    do: Enum.map(args, fn arg -> arg <> " is on a very long line!" end)
  ```
* `do:` 子句跟函数定义部分在同一行时候，需要使用空行分割函数
  ```elixir
  # 不期望
  def some_function([]), do: :empty
  def some_function(_),
    do: :very_long_line_here

  # 期望
  def some_function([]), do: :empty

  def some_function(_),
    do: :very_long_line_here
  ```
* 使用空行分割多个变量分配（绑定）部分，从而区分变量的分配完毕
  ```elixir
  # 不期望
  some_string =
    "Hello"
    |> String.downcase()
    |> String.trim()
  another_string <> some_string

  # 期望
  some_string =
    "Hello"
    |> String.downcase()
    |> String.trim()

  another_string <> some_string

  # also not preferred
  something =
    if x == 2 do
      "Hi"
    else
      "Bye"
    end
  String.downcase(something)

  # 期望
  something =
    if x == 2 do
      "Hi"
    else
      "Bye"
    end

  String.downcase(something)
  ```
* 如果 **List，Map，Struct** 之类的数据结构需要跨越多行，那就把它们的每个元素独占一行，同时缩进一级除了括号的之外的每个元素
  ```elixir
  # 不期望
  [:first_item, :second_item, :next_item,
  :final_item]

  # 期望
  [
    :first_item,
    :second_item,
    :next_item,
    :final_item
  ]
  ```
* 当分配（绑定）**List，Map，Struct** 之类的数据结构时，保持括号的开始端和分配（绑定）操作在同一行
  ```elixir
  # 不期望
  list =
  [
    :first_item,
    :second_item
  ]

  # 期望
  list = [
    :first_item,
    :second_item
  ]
  ```
* 当 cond 或者 case 子句跨越多行的时候，用空号分割它们的子句
  ```elixir
  # 不期望
  case arg do
    true ->
      :ok
    false ->
      :error
  end

  # 期望
  case arg do
    true ->
      :ok

    false ->
      :error
  end
  ```
* 注释需要放在她们描述部分的上方
  ```elixir
  String.first(some_string) # 不期望

  # 期望
  String.first(some_string)
  ```
* 在 `#` 后用一个空格分割注释的文本内容
  ```elixir
  #not preferred
  String.first(some_string)

  # 期望
  String.first(some_string)
  ```
* 缩进和换行对齐 `with` 的子句，包括 `do:` 部分也需要换行缩进对齐
  ```elixir
  with {:ok, foo} <- fetch(opts, :foo),
       {:ok, my_var} <- fetch(opts, :my_var),
       do: {:ok, foo, my_var}
  ```
* 如果 `with` 表达式的 `do` 子句有多行，使用多行对齐的方式
  ```elixir
  with {:ok, foo} <- fetch(opts, :foo),
       {:ok, my_var} <- fetch(opts, :my_var) do
    {:ok, foo, my_var}
  else
    :error ->
      {:error, :bad_arg}
  end
  ```
* 当调用零元函数时，在使用管道操作符 `|>` 连接下，需要使用带括号 `()` 的调用方式
  ```elixir
  # 不期望
  some_string |> String.downcase |> String.trim

  # 期望
  some_string |> String.downcase() |> String.trim()
  ```
* 在函数调用的时候，函数名和括号之间不要加上空格
  ```elixir
  # 不期望
  f (3 + 2)

  # 期望
  f(3 + 2)
  ```
* 所有的函数调用都应该加上括号，特别是在管道操作符号里面
  ```elixir
  # 不期望
  f 3

  # 期望
  f(3)

  # 不建议，并且这会解析成非你期望的样子 rem(2, (3 |> g))。
  2 |> rem 3 |> g

  # 期望
  2 |> rem(3) |> g
  ```
* 当函数调用里面的 `keyword` list 参数，应该省略掉括号
  ```elixir
  # 不期望
  some_function(foo, bar, [a: "baz", b: "qux"])

  # 期望
  some_function(foo, bar, a: "baz", b: "qux")
  ```

---

#### `Mix.Tasks.Format` 可能无法自动格式化的部分

* 相同模式匹配方式的函数定义，使用单行 `def` 的定义方式，其他情况使用多行 `def` 方式
  ```elixir
  def some_function(nil), do: {:error, "No Value"}
  def some_function([]), do: :ok

  def some_function([first | rest]) do
    some_function(rest)
  end
  ```
* 如果不止一个的多行 `def` ，不要使用单行 `def` 的定义方式
  ```elixir
  def some_function(nil) do
    {:error, "No Value"}
  end

  def some_function([]) do
    :ok
  end

  def some_function([first | rest]) do
    some_function(rest)
  end

  def some_function([first | rest], opts) do
    some_function(rest, opts)
  end
  ```
* 使用管道操作符把函数链接在一起
  ```elixir
  # 不期望
  String.trim(String.downcase(some_string))

  # 期望
  some_string |> String.downcase() |> String.trim()

  # 多行管道操作不应该缩进
  some_string
  |> String.downcase()
  |> String.trim()

  # 多行管道在模式匹配的右边应该使用新的一行开始并缩进
  sanitized_string =
    some_string
    |> String.downcase()
    |> String.trim()
  ```
* 避免只使用一次管道操作符的情况
  ```elixir
  # 不期望
  some_string |> String.downcase()

  # 期望
  String.downcase(some_string)
  ```
* 把函数链中最初始的值放在第一部分
  ```elixir
  # 不期望
  String.trim(some_string) |> String.downcase() |> String.codepoints()

  # 期望
  some_string |> String.trim() |> String.downcase() |> String.codepoints()
  ```
* `def` 定义带参数的时候，都使用括号的方式
  ```elixir
  # 不期望
  def some_function arg1, arg2 do
    # body omitted
  end

  def some_function() do
    # body omitted
  end

  # 期望
  def some_function(arg1, arg2) do
    # body omitted
  end

  def some_function do
    # body omitted
  end
  ```
* `if/unless` 只有单行定义的时候，使用 `do:` 的方式
  ```elixir
  # 期望
  if some_condition, do: # some_stuff
  ```
* 使用 `unless` 的时候不要使用 `else` 分支，应该用其他方式来重构，比如 `if`
  ```elixir
  # 不期望
  unless success do
    IO.puts('failure')
  else
    IO.puts('success')
  end

  # 期望
  if success do
    IO.puts('success')
  else
    IO.puts('failure')
  end
  ```
* 使用 `cond` 的时候，在最后的分支使用 `ture` 来保证模式匹配总是成功的  
  ```elixir
  # 不期望
  cond do
    1 + 2 == 5 ->
      "Nope"

    1 + 3 == 5 ->
      "Uh, uh"

    :else ->
      "OK"
  end

  # 期望
  cond do
    1 + 2 == 5 ->
      "Nope"

    1 + 3 == 5 ->
      "Uh, uh"

    true ->
      "OK"
  end
  ```
* 零元函数在调用的时候，使用带括号的方式，这样子可以方便区分函数和变量  
  ```elixir
  defp do_stuff, do: ...

  # 不期望
  def my_func do
    # is this a variable or a function call?
    do_stuff
  end

  # 期望
  def my_func do
    # this is clearly a function call
    do_stuff()
  end
  ```
* 对于原子、函数和变量使用蛇形蛇形命名法（snake_case） 
  ```elixir
  # 不期望
  :"some atom"
  :SomeAtom
  :someAtom

  someVar = 5

  def someFunction do
    ...
  end

  # 期望
  :some_atom

  some_var = 5

  def some_function do
    ...
  end
  ```
* 对于模块名使用驼峰命名法（CamelCase），对于首字母缩略词保持大写  
  ```elixir
  # 不期望
  defmodule Somemodule do
    ...
  end

  defmodule Some_Module do
    ...
  end

  defmodule SomeXml do
    ...
  end

  # 期望
  defmodule SomeModule do
    ...
  end

  defmodule SomeXML do
    ...
  end
  ```
* 对于谓词宏使用 `is_` 前缀命名，对于谓词函数在函数名后加 `?` 来命名  
  ```elixir
  defmacro is_cool(var) do
    quote do: unquote(var) == "cool"
  end

  def cool?(var) do
    # Complex check if var is cool not possible in a pure function.
  end
  ```
* 私有函数如果和共有函数命名一样，那么给私有函数加上 `do_` 前缀  
  ```elixir
  def sum(list), do: do_sum(list, 0)

  # 私有函数
  defp do_sum([], total), do: total
  defp do_sum([head | tail], total), do: do_sum(tail, head + total)
  ```
* 尽可能通过你写的控制流，结构，命名来表达你的代码功能
* 注释太长，使用分段写，并在句子里加标点符号
  ```elixir
  # 不期望
  # these lowercase comments are missing punctuation

  # 期望
  # Capitalization example
  # Use punctuation for complete sentences.
  ```
* 一行注释不超过 100 个字符
* 注释应该写在相关联的代码上方
* 注释的关键字使用大写，并且用冒号和空格分割内容
  ```elixir
  # TODO: Deprecate in v1.5.
  def some_function(arg), do: {:ok, arg}
  ```
* 如果程序表达意图很清楚，没必要写多余的注释
  ```elixir
  start_task()

  # FIXME
  Process.sleep(5000)
  ```
* 使用 `TODO` 标识需要以后完成的功能
* 使用 `FIXME` 标识需要修复的功能
* 使用 `OPTIMIZE` 标识需要优化的功能
* 使用 `HACK` 标识需要重构的功能
* 使用 `REVIEW` 标识需要检阅的功能
* 使用其他可能潜在方便标识的关键字描述意图
* 一个模块一个文件，除非这些模块是给其他模块作为内部使用的（比如测试模块）
* 文件名用蛇形命名法，模块名用驼峰命名法
  ```elixir
  # file is called some_module.ex

  defmodule SomeModule do
  end
  ```
* 模块名，基于模块所在的目录和文件名来命名。
  ```
  # 文件在这个路径下 parser/core/xml_parser.ex

  defmodule Parser.Core.XMLParser do
  end
  ```
* 以下模块属性和指令按照上到下排序，使用空行分割它们，并且它们内部基于字典序排序
  ```elixir
  ######################
  # @moduledoc
  # @behaviour
  # use
  # import
  # alias
  # require
  # @module_attribute
  # defstruct
  # @type
  # @callback
  # @macrocallback
  # @optional_callbacks
  ######################
  defmodule MyModule do
    @moduledoc """
    An example module
    """

    @behaviour MyBehaviour

    use GenServer

    import Something
    import SomethingElse

    alias My.Long.Module.Name
    alias My.Other.Module.Example

    require Integer

    @module_attribute :foo
    @other_attribute 100

    defstruct [:name, params: []]

    @type params :: [{binary, binary}]

    @callback some_function(term) :: :ok | {:error, term}

    @macrocallback macro_name(term) :: Macro.t()

    @optional_callbacks macro_name: 1

    ...
  end
  ```
* 使用 `__MODULE__` 来引用模块自身，这样子可以避免修改模块名的时候，需要代码内部全部修改。
  ```elixir
  defmodule SomeProject.SomeModule do
    defstruct [:name]

    def name(%__MODULE__{name: name}), do: name
  end
  ```
* 如需更美观的自引用模块，可以使用别名
  ```elixir
  defmodule SomeProject.SomeModule do
    alias __MODULE__, as: SomeModule

    defstruct [:name]

    def name(%SomeModule{name: name}), do: name
  end
  ```
* 避免模块名和命名空间有重复的名字
  ```elixir
  # 不期望
  defmodule Todo.Todo do
    ...
  end

  # 期望
  defmodule Todo.Item do
    ...
  end
  ```
* 在 `defmodule` 的下一行应该增加 `@moduledoc` 描述模块的作用
  ```elixir
  # 不期望

  defmodule AnotherModule do
    use SomeModule

    @moduledoc """
    About the module
    """
    ...
  end

  # 期望

  defmodule AThirdModule do
    @moduledoc """
    About the module
    """

    use SomeModule
    ...
  end
  ```
* 如果你不想给模块写文档，使用 `@moduledoc false`
  ```elixir
  defmodule SomeModule do
    @moduledoc false
    ...
  end
  ```
* 用空行分割代码和 `@moduledoc`
  ```elixir
  # 不期望
  defmodule SomeModule do
    @moduledoc """
    About the module
    """
    use AnotherModule
  end

  # 期望
  defmodule SomeModule do
    @moduledoc """
    About the module
    """

    use AnotherModule
  end
  ```
* 使用 `heredocs` 和 `markdown` 来书写文档
  ```elixir
  # 不期望
  defmodule SomeModule do
    @moduledoc "About the module"
  end

  defmodule SomeModule do
    @moduledoc """
    About the module

    Examples:
    iex> SomeModule.some_function
    :result
    """
  end

  # 期望
  defmodule SomeModule do
    @moduledoc """
    About the module

    ## Examples

        iex> SomeModule.some_function
        :result
    """
  end
  ```
* Typespecs 可以用来定义类型和规划，用于文档注释和静态分析工具 `Dialyzer`，自定义的类型放在模块顶部
* @typedoc 和 @type 定义在一起，每一对用空行分割
  ```elixir
  defmodule SomeModule do
    @moduledoc false

    @typedoc "The name"
    @type name :: atom

    @typedoc "The result"
    @type result :: {:ok, term} | {:error, term}

    ...
  end
  ```
* 如果定义联合类型太长了，可以使用多行分割每一个类型，并且缩进一个级别
  ```elixir
  # 不期望
  @type long_union_type ::
          some_type | another_type | some_other_type | one_more_type | a_final_type

  # 期望
  @type long_union_type ::
          some_type
          | another_type
          | some_other_type
          | one_more_type
          | a_final_type
  ```
* 使用 t 来描述模块的主要类型，例如：定义个结构体类型
  ```elixir
  defstruct [:name, params: []]

  @type t :: %__MODULE__{
          name: String.t() | nil,
          params: Keyword.t()
        }
  ```
* 在函数定义上方使用类型描述
  ```elixir
  @spec some_function(term) :: result
  def some_function(some_data) do
    {:ok, some_data}
  end
  ```
* `struct` 定义中，当字段需要默认值为 `nil` 时，使用 `list` 的方式定义 `struct` 
  ```elixir
  # 不期望
  defstruct name: nil, params: nil, active: true

  # 期望
  defstruct [:name, :params, active: true]
  ```
* 当 `defstruct` 定义时，字段是正常的 `keyword` 列表，省略括号
  ```elixir
  # 不期望
  defstruct [params: [], active: true]

  # 期望
  defstruct params: [], active: true

  # 必须
  defstruct [:name, params: [], active: true]
  ```
* 如果 `struct` 定义需要使用多行，那确保每一行一个元素并且对齐，如果使用列表定义，就根据多行列表的方式来格式化
  ```elixir
  defstruct foo: "test",
          bar: true,
          baz: false,
          qux: false,
          quux: 1

  defstruct [
    :name,
    params: [],
    active: true
  ]
  ```
* 自定义异常的名字使用 `Error` 结尾
  ```elixir
  # 不期望
  defmodule BadHTTPCode do
    defexception [:message]
  end

  defmodule BadHTTPCodeException do
    defexception [:message]
  end

  # 期望
  defmodule BadHTTPCodeError do
    defexception [:message]
  end
  ```
* 异常错误的文本内容使用小写并且在末尾不使用标点符号
  ```elixir
  # 不期望
  raise ArgumentError, "This is not valid."

  # 期望
  raise ArgumentError, "this is not valid"
  ```
* 所有的 `keyword` 列表都使用特殊语法
  ```elixir
  # 不期望
  some_value = [{:a, "baz"}, {:b, "qux"}]

  # 期望
  some_value = [a: "baz", b: "qux"]
  ```
* 在 `map` 结构中，如果所有 `key` 值都是 `atom` 时，使用速记语法
  ```elixir
  # 不期望
  %{:a => 1, :b => 2, :c => 0}

  # 期望
  %{a: 1, b: 2, c: 3}
  ```
* 在 `map` 结构中，如果有 `key` 值不是 `atom` 时，使用详记语法
  ```elixir
  # 不期望
  %{"c" => 0, a: 1, b: 2}

  # 期望
  %{:a => 1, :b => 2, "c" => 0}
  ```
* 使用二进制连接符来操作二进制字符串连接
  ```elixir
  # 不期望
  <<"my"::utf8, _rest::bytes>> = "my string"

  # 期望
  "my" <> _rest = "my string"
  ```
* 避免不必要的宏操作
* ExUnit 断言中，测试值放在操作符左边，期望值放在操作符右边，除非是模式匹配的情况
  ```elixir
  # 期望
  assert actual_function(1) == true

  # 不期望
  assert true == actual_function(1)

  # 必须 - 断言是一个模式匹配
  assert {:ok, expected} = actual_function(3)
  ```

---

### Elixir Credo —— 代码分析工具
Credo 是 Elixir 的代码分析工具，可以分析 Elixir 项目中的圈复杂度（Cyclomatic complexity，简写CC），还能分析 Elixir 项目中常见的错误和代码可读性。

#### Credo 使用方式
1. 在 `mix.exs` 中填写依赖
  ```elixir
  defp deps do
    [
      {:credo, "~> 1.0.0", only: [:dev, :test], runtime: false}
    ]
  end
  ```
2. 使用 `mix credo` 来获取报告
3. 使用 `mix credo --strict` 获取更加严格的报告
4. 使用 `mix credo list` 获取按照文件分组的报告

#### Credo 配置
使用 `mix credo.gen.config` 来创建配置文件
  ```elixir
  %{
    # 在 `configs:` 中可以荣有多个配置
    configs: [
      %{
        # 使用 `mix credo -C <name>` 来执行对应的配置名，默认使用 default
        name: "default",

        # 配置需要分析的文件:
        files: %{

          #  可以使用明确的目录或者文件，模糊匹配也支持，比如 `**/*.{ex,exs}`
          included: ["lib/", "src/", "test/", "web/", "apps/"],
          excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
        },

        # 如果使用自定义 check 文件，可以在这里引入，
        # Credo 在分析之前加载的
        requires: [],

        # 如果需要严格的风格金策，可以在下面设置 true
        strict: false,

        # 如果不需要给输出报告配置色彩，可以在下面设置 false
        color: true,
        
        # 如果需要定制配置，可以在下面配置元组里面修改
        # 如果需要关闭某个 chect，可以在元组的第二个元素配置 false
        #
        #     {Credo.Check.Design.DuplicatedCode, false}
        #
        checks: [
          #
          ## Consistency Checks
          #
          {Credo.Check.Consistency.ExceptionNames, []},
          {Credo.Check.Consistency.LineEndings, []},
          {Credo.Check.Consistency.ParameterPatternMatching, []},
          {Credo.Check.Consistency.SpaceAroundOperators, []},
          {Credo.Check.Consistency.SpaceInParentheses, []},
          {Credo.Check.Consistency.TabsOrSpaces, []},

          #
          ## Design Checks
          #
          # 可以自定义 Check 配置优先级
          # 优先级有: `low, normal, high, higher`
          #
          {Credo.Check.Design.AliasUsage,
          [priority: :low, if_nested_deeper_than: 2, if_called_more_often_than: 0]},

          # 可以给每个 Check 自定义结束状态
          # 如果你不希望 TODO 注释会在 `mix credo` 运行时导致错误,
          # 只需要配置为 0 (zero).
          {Credo.Check.Design.TagTODO, [exit_status: 2]},
          {Credo.Check.Design.TagFIXME, []},

          #
          ## Readability Checks
          #
          {Credo.Check.Readability.AliasOrder, []},
          {Credo.Check.Readability.FunctionNames, []},
          {Credo.Check.Readability.LargeNumbers, []},
          {Credo.Check.Readability.MaxLineLength, [priority: :low, max_length: 120]},
          {Credo.Check.Readability.ModuleAttributeNames, []},
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Readability.ModuleNames, []},
          {Credo.Check.Readability.ParenthesesInCondition, []},
          {Credo.Check.Readability.ParenthesesOnZeroArityDefs, []},
          {Credo.Check.Readability.PredicateFunctionNames, []},
          {Credo.Check.Readability.PreferImplicitTry, []},
          {Credo.Check.Readability.RedundantBlankLines, []},
          {Credo.Check.Readability.Semicolons, []},
          {Credo.Check.Readability.SpaceAfterCommas, []},
          {Credo.Check.Readability.StringSigils, []},
          {Credo.Check.Readability.TrailingBlankLine, []},
          {Credo.Check.Readability.TrailingWhiteSpace, []},
          # TODO: enable by default in Credo 1.1
          {Credo.Check.Readability.UnnecessaryAliasExpansion, false},
          {Credo.Check.Readability.VariableNames, []},

          #
          ## Refactoring Opportunities
          #
          {Credo.Check.Refactor.CondStatements, []},
          {Credo.Check.Refactor.CyclomaticComplexity, []},
          {Credo.Check.Refactor.FunctionArity, []},
          {Credo.Check.Refactor.LongQuoteBlocks, []},
          {Credo.Check.Refactor.MapInto, []},
          {Credo.Check.Refactor.MatchInCondition, []},
          {Credo.Check.Refactor.NegatedConditionsInUnless, []},
          {Credo.Check.Refactor.NegatedConditionsWithElse, []},
          {Credo.Check.Refactor.Nesting, []},
          {Credo.Check.Refactor.PipeChainStart,
          [
            excluded_argument_types: [:atom, :binary, :fn, :keyword, :number],
            excluded_functions: []
          ]},
          {Credo.Check.Refactor.UnlessWithElse, []},

          #
          ## Warnings
          #
          {Credo.Check.Warning.BoolOperationOnSameValues, []},
          {Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},
          {Credo.Check.Warning.IExPry, []},
          {Credo.Check.Warning.IoInspect, []},
          {Credo.Check.Warning.LazyLogging, []},
          {Credo.Check.Warning.OperationOnSameValues, []},
          {Credo.Check.Warning.OperationWithConstantResult, []},
          {Credo.Check.Warning.RaiseInsideRescue, []},
          {Credo.Check.Warning.UnusedEnumOperation, []},
          {Credo.Check.Warning.UnusedFileOperation, []},
          {Credo.Check.Warning.UnusedKeywordOperation, []},
          {Credo.Check.Warning.UnusedListOperation, []},
          {Credo.Check.Warning.UnusedPathOperation, []},
          {Credo.Check.Warning.UnusedRegexOperation, []},
          {Credo.Check.Warning.UnusedStringOperation, []},
          {Credo.Check.Warning.UnusedTupleOperation, []},

          #
          # 如果需要使用还有争议的实验性 Check (只需要替换 `false` 成 `[]`)
          #
          {Credo.Check.Consistency.MultiAliasImportRequireUse, false},
          {Credo.Check.Design.DuplicatedCode, false},
          {Credo.Check.Readability.MultiAlias, false},
          {Credo.Check.Readability.Specs, false},
          {Credo.Check.Refactor.ABCSize, false},
          {Credo.Check.Refactor.AppendSingleItem, false},
          {Credo.Check.Refactor.DoubleBooleanNegation, false},
          {Credo.Check.Refactor.ModuleDependencies, false},
          {Credo.Check.Refactor.VariableRebinding, false},
          {Credo.Check.Warning.MapGetUnsafePass, false},
          {Credo.Check.Warning.UnsafeToAtom, false}

          #
          # 自定义的 Check 可以使用 `mix credo.gen.check` 来创建
          #
        ]
      }
    ]
  }
  ```
#### 内置的 Credo 注释配置
* credo:disable-for-this-file - 忽略整个文件的检测  
* credo:disable-for-next-line - 忽略下一行的检测  
* credo:disable-for-previous-line - 忽略上一行的检测  
* credo:disable-for-lines:<count> - 忽略多行检测（负数指往上 N 行）  
例子：
  ```elixir
  defp do_stuff() do
    # credo:disable-for-next-line
    IO.inspect {:we_want_this_inspect_in_production!}
  end

  defp my_fun() do
    # credo:disable-for-next-line Credo.Check.Warning.IoInspect
    IO.inspect {:we_want_this_inspect_in_production!}
  end
  ```
####  Credo 的结束状态
结束状态不等于 0 的，Credo 都会有错误报告
  ```
  consistency:  1
  design:       2
  readability:  4
  refactor:     8
  warning:     16
  ```
但是结束状态为 12 只是 Readability 问题，可以选择性重构

**更多命令相关的参数请参考 https://github.com/rrrene/credo**