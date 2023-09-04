# CF-Turnstile

## Credits

* https://github.com/Nexus-Mods/hcaptcha
* https://github.com/Retrospring/hcaptcha
* https://github.com/firstmoversadvantage/hcaptcha
* https://github.com/ambethia/recaptcha

## WARNING
Missing tests.

## Overview

License:   [MIT](http://creativecommons.org/licenses/MIT/)

This gem provides helper methods for the [Cloudflare Turnstile API](https://developers.cloudflare.com/turnstile/). In your
views you can use the `turnstile_tags` method to embed the needed javascript, and you can validate
in your controllers with `verify_turnstile` or `verify_turnstile!`.

## Obtaining a key and setup

Go to the [Cloudflare dashboard](https://dash.cloudflare.com/?to=/:account/turnstile) and generate API keys. 
See the Turnstile [Get started](https://developers.cloudflare.com/turnstile/get-started/) page for more information.

## Installation

First, add the gem to your Gemfile:
```shell
gem 'cf-turnstile', github: 'valeriy-sokoloff/cf-turnstile', require: 'turnstile'
```

Then run `bundle install`

Then, set the following environment variables:
* `TURNSTILE_SECRET_KEY`
* `TURNSTILE_SITE_KEY`

or in case you're using Rails, create an `turnstile.rb` initializer:
```ruby
Turnstile.configure do |config|
  config.site_key  = '<your_site_key>'
  config.secret_key = '<your_secret_key>'
end
```

> 💡 You should keep keys out of your codebase with external environment variables (using your shell's `export` command), Rails (< 5.2) [secrets](https://guides.rubyonrails.org/v5.1/security.html#custom-secrets), Rails (5.2+) [credentials](https://guides.rubyonrails.org/security.html#custom-credentials), the [dotenv](https://github.com/bkeepers/dotenv) or [figaro](https://github.com/laserlemon/figaro) gems, …

## Usage

First, add `turnstile_tags` to the forms you want to protect:

```erb
<%= form_for @foo do |f| %>
  # …
  <%= turnstile_tags %>
  # …
<% end %>
```

Then, add `verify_turnstile` logic to each form action that you've protected:

```ruby
# app/controllers/users_controller.rb
@user = User.new(params[:user].permit(:name))
if verify_turnstile(model: @user) && @user.save
  redirect_to @user
else
  render 'new'
end
```

If you are **not using Rails**, you should:
* `include Turnstile::Adapters::ViewMethods` where you need `turnstile_tags`
* `include Turnstile::Adapters::ControllerMethods` where you need `verify_turnstile`

### API details

### `turnstile_tags(options = {})`

Use in your views to render the JavaScript widget.

Available options:

| Option                         | Description                                                                                                                                      |
|--------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
| `:action`                      | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:cdata`                       | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:callback`                    | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:error_callback`              | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:execution`                   | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:expired_callback`            | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:class`                       | Additional CSS classes added to `cf-turnstile` on the placeholder                                                                                |
| `:external_script`             | _alias for `:script` option_                                                                                                                     |
| `:before_interactive_callback` | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:after_interactive_callback`  | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:unsupported_callback`        | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:theme`                       | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_ (default: `:dark`) |
| `:language`                    | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:tabindex`                    | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:timeout_callback`            | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:script_async`                | Add `async` attribute to the `<script>` tag (default: `true`)                                                                                    |
| `:script_defer`                | Add `defer` attribute to the `<script>` tag (default: `true`)                                                                                    |
| `:script`                      | Generate the `<script>` tag (default: `true`)                                                                                                    |
| `:site_key`                    | Set Turnstile Site Key (overrides `TURNSTILE_SITE_KEY` environment variable)                                                                     |
| `:size`                        | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:retry`                       | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:retry_interval`              | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:refresh_expired`             | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |
| `:appearance`                  | _see [official documentation](https://developers.cloudflare.com/turnstile/get-started/client-side-rendering/#configurations)_                    |

> ℹ️ Unkown options will be passed directly as attributes to the placeholder element.
>
> For example, `turnstile_tags(foo: "bar")` will generate the default script tag and the following placeholder tag:
> ```html
> <div class="cf-turnstile" data-sitekey="…" foo="bar"></div>
> ```

### `verify_turnstile`

This method returns `true` or `false` after processing the response token from the Turnstile widget.
This is usually called from your controller.

Passing in the ActiveRecord object via `model: object` is optional. If you pass a `model`—and the
captcha fails to verify—an error will be added to the object for you to use (available as
`object.errors`).

Why isn't this a model validation? Because that violates MVC. You can use it like this, or how ever
you like.

Some of the options available:

| Option        | Description                                                                                                                                                                                                                                                                                                   |
|---------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `:model`      | Model to set errors.                                                                                                                                                                                                                                                                                          |
| `:attribute`  | Model attribute to receive errors. (default: `:base`)                                                                                                                                                                                                                                                         |
| `:message`    | Custom error message.                                                                                                                                                                                                                                                                                         |
| `:secret_key` | Override the secret API key from the configuration.                                                                                                                                                                                                                                                           |
| `:timeout`    | The number of seconds to wait for Turnstile servers before give up. (default: `3`)                                                                                                                                                                                                                            |
| `:response`   | Custom response parameter. (default: `params['cf-turnstile-response']`)                                                                                                                                                                                                                                       |
| `:hostname`   | Expected hostname or a callable that validates the hostname, see [domain validation](https://developers.google.com/recaptcha/docs/domain_validation) and [hostname](https://developers.google.com/recaptcha/docs/verify#api-response) docs. (default: `nil`, but can be changed by setting `config.hostname`) |
| `:env`        | Current environment. The request to verify will be skipped if the environment is specified in configuration under `skip_verify_env`                                                                                                                                                                           |

## I18n support

Turnstile supports the I18n gem (it comes with English translations)
To override or add new languages, add to `config/locales/*.yml`

```yaml
# config/locales/en.yml
en:
  turnstile:
    errors:
      verification_failed: Turnstile verification failed, please try again.
      recaptcha_unreachable: Oops, we failed to validate your Turnstile response. Please try again.
```

## Testing

By default, Turnstile is skipped in "test" and "cucumber" env. To enable it during test:

```ruby
Turnstile.configuration.skip_verify_env.delete("test")
```
