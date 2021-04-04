package slack

import (
	"errors"
	"fmt"
	"net/http"
	"net/url"
)

type Slack struct {
	Token       string
	EmailLookup map[string]*User
	Client      *http.Client
}

func New(token string) *Slack {
	return &Slack{
		Token:       token,
		EmailLookup: make(map[string]*User),
	}
}

func (s *Slack) UserByEmail(email string) (*User, error) {
	if email == "" {
		return nil, errors.New("missing email")
	}

	u, ok := s.EmailLookup[email]
	if !ok {
		users, err := s.Users()
		if err != nil {
			return nil, err
		}
		for _, u := range users {
			s.EmailLookup[u.Profile.Email] = u
		}
		u, ok = s.EmailLookup[email]
		if !ok {
			return nil, fmt.Errorf("email %q not found", email)
		}
	}
	return u, nil
}

type Profile struct {
	Email     string `json:"email"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	Image24   string `json:"iamge_24"`
	Image32   string `json:"iamge_32"`
	Image48   string `json:"iamge_48"`
	Image72   string `json:"iamge_72"`
	Image192  string `json:"iamge_192"`
}
type User struct {
	ID      string  `json:"id"`
	Name    string  `json:"name"`
	Profile Profile `json:"profile"`
}

func (s *Slack) Users() ([]*User, error) {
	type apiResponse struct {
		Members []*User `json:"members"`
	}

	var data apiResponse
	err := s.call("users.list", url.Values{}, &data)
	if err != nil {
		return nil, err
	}
	return data.Members, nil
}

type Message struct {
	Channel   string
	Text      string
	Username  string
	AsUser    bool
	IconURL   string
	IconEmoji string
}

func (m *Message) Params() url.Values {
	_bool := func(a bool) string {
		switch a {
		case true:
			return "true"
		case false:
			return "false"
		default:
			panic("here")
		}
	}

	params := url.Values{
		"channel":      []string{m.Channel},
		"text":         []string{m.Text},
		"username":     []string{m.Username},
		"as_user":      []string{_bool(m.AsUser)},
		"link_name":    []string{"0"},
		"unfurl_links": []string{"false"},
		"unfurl_media": []string{"false"},
		"icon_url":     []string{m.IconURL},
		"icon_emoji":   []string{m.IconEmoji},
	}
	return params
}

func (s *Slack) ChatPostMessage(msg *Message) error {
	return s.call("chat.postMessage", msg.Params(), nil)
}
