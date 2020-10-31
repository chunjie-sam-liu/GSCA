import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DegComponent } from './deg.component';

describe('DegComponent', () => {
  let component: DegComponent;
  let fixture: ComponentFixture<DegComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DegComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DegComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
