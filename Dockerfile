FROM ruby:2.4-onbuild

# /usr/src/app
CMD ["ruby", "fdreamd.rb", "--disable-jabber"]
