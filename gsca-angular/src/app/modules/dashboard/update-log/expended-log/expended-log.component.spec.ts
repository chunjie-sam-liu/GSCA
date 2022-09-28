import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ExpendedLogComponent } from './expended-log.component';

describe('ExpendedLogComponent', () => {
  let component: ExpendedLogComponent;
  let fixture: ComponentFixture<ExpendedLogComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ExpendedLogComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ExpendedLogComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
