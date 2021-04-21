import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { PparComponent } from './ppar.component';

describe('PparComponent', () => {
  let component: PparComponent;
  let fixture: ComponentFixture<PparComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ PparComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(PparComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
