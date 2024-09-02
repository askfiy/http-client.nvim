# README

<h3 align="center">
http-client.nvim
</h3>

<h6 align="center">
<img src="https://github.com/user-attachments/assets/5a7974c7-72bc-44d9-9492-f1c2ee8301bc" alt="" width="100%">
</h6>

<h6 align="center">
Elegant neovim request client implementation
</h6>

<div style="font-size:.8rem; font-weight:lighter;color:#E95793">
<center>
<p>http-client.nvim is a Neovim plugin designed to help users quickly and easily send HTTP requests directly from within Neovim.</p>
<p>The plugin supports multiple request formats and file uploads, offering developers a flexible and efficient way to manage HTTP interactions.<p>
</center>
</div>

## Features

> Isn't it better to be simple?

- Pure asynchronous support
- Simple configuration
- Clear structure
- A small amount of dependency

## Install and Use

> [!IMPORTANT]
>
> Please ensure the following dependencies are installed:
>
> - `curl`
> - [tree-sitter-http](https://github.com/rest-nvim/tree-sitter-http)

To install using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "askfiy/http-client.nvim",
    priority = 100,
    config = function()
        require("http-client").setup()
    end,
}
```

> [!IMPORTANT]
>
> For usage examples, see: [test.http](./test/test.http)

## Default Configuration

**http-client.nvim** provides some default configuration options, keeping the setup as simple as possible:

```lua
local config = {
    client = "curl",
    animation = {
        spinner = { "|", "/", "-", "\\" },
        interval = 100,
    },
    extmark = {
        still = {
            virt_text = "Send Request",
            hl_group = "Comment",
        },
        active = {
            virt_text = "Sending",
            hl_group = "Comment",
        },
    },
    render = {
        open = {
            width = nil, -- nil | number
            height = nil, -- nil | number,
            focus = true,
        },
        keybinds = {
            help = "?",
            copy_curl_command = "<leader>cp",
        },
    },
    hooks = {
        process_request = function(request)
            return request
        end,
        process_response = function(response)
            return response
        end,
        process_template_render = function(request, response, template)
            return template
        end,
        process_exception_render = function(request, response, template)
            return template
        end,
    },
}
```

## Plugin Commands

The plugin provides 3 commands:

- `HttpClient lastRender` - Renders the last request result
- `HttpClient lastRequest` - Resends the last request
- `HttpClient sendRequest` - Sends the request under the current cursor

## Project Structure

A clear project structure is key to easy maintenance and contributions:

<h6 align="center">
<img src="https://github.com/user-attachments/assets/87d7de69-dab5-45e0-a176-fad7a601d222" alt="" width="90%">
</h6>

## Similar

rest.nvim and kulala.nvim do a very good job. They are all excellent plugins of the same type:

- [rest.nvim](https://github.com/rest-nvim/rest.nvim)
- [kulala.nvim](https://github.com/mistweaverco/kulala.nvim)

## License

This plugin is licensed under the MIT License. See the [LICENSE](https://github.com/askfiy/http-client.nvim/blob/master/LICENSE) file for details.

## Contributing

Contributions are welcome! If you encounter a bug or want to enhance this plugin, feel free to open an issue or create a pull request.
