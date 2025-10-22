const request = require('supertest');
const { expect } = require('chai');
const app = require('../server');

describe('API Endpoints', () => {
  
  describe('GET /', () => {
    it('should return welcome message', (done) => {
      request(app)
        .get('/')
        .expect(200)
        .end((err, res) => {
          if (err) return done(err);
          expect(res.body).to.have.property('message');
          expect(res.body.status).to.equal('running');
          done();
        });
    });
  });

  describe('GET /health', () => {
    it('should return healthy status', (done) => {
      request(app)
        .get('/health')
        .expect(200)
        .end((err, res) => {
          if (err) return done(err);
          expect(res.body.status).to.equal('healthy');
          expect(res.body).to.have.property('timestamp');
          done();
        });
    });
  });

  describe('GET /api/users', () => {
    it('should return list of users', (done) => {
      request(app)
        .get('/api/users')
        .expect(200)
        .end((err, res) => {
          if (err) return done(err);
          expect(res.body).to.have.property('users');
          expect(res.body.users).to.be.an('array');
          expect(res.body.users).to.have.lengthOf(2);
          done();
        });
    });
  });

});